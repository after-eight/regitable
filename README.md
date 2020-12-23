# reGitable - backup your reMarkable using git

# [<img src="perfectgit2.png"></p>](https://github.com/after-eight/regitable)

## Objective

Most of my digital life is stored in a git repository, so the first thing i thought of when i examined my newly arrived reMarkable2 was: can i install and use git on it?

The filesystem layout of the reMarkable meets the requirements for a git repository pretty well.
Besides the binary `.rm` and `.jpg` files, all other files are more or less json-formatted text files.
Plus, the filenames are immutable uuids, so even if you rename a notebook or move it from one folder to another, all that changes is the `parent` entry in the `.metadata` file.

Even though the `.jpg` files are tiny, because they get compressed really hard and with low quality, and the `.rm` files don't grow _that_ large because they're one file per page, yet i decided to go the git-lfs route. The setup is a bit more complex, but most of the work is done by the install script anyways, and the result is absolutely worth it.

By pushing changes to a remote repository instantly, i do not only have a backup of all my notebooks in the cloud.
The repository contains all the back-versions of my files, and should i need to return to a long ago previous version of a file, or have to recover a deleted file, i can simply check it out of my repository and re-upload it onto my reMarkable.

If you're a little paranoid like me, simply install a privately hosted GitLab instance, and all your files are completely under your control.

Though git of course knows push as well as pull operations in all repositories, i use this solution as a "one way street" (aka backup).
I only do pushes from the reMarkable, never pull.
All other clients should only be used to pull, never push.


<!-- ------------------------------------------------------------------- -->


## Prerequisites

### Entware

Before you can install and use reGitable, you have to install [reMarkable Entware](https://github.com/evidlo/remarkable_entware).

The installation is very easy and straight forward, thanks to Evan Widloski at this point.

### Git-LFS

Unfortunately, the git-lfs package is not (yet) available via Entware.

The reGitable install script will download the latest arm-release directly from their GitHub Site and install it for you.


### Remote Repository

Both GitHub and GitLab offer private repos for free, which is the easiest way to get started. Simply create a new repository (leave it "blank", do not create a `README.md` file), upload the public ssh key that is created for you during the installation of reGitable, and you are ready to go.

To increase privacy, you can use an on-premise GitLab installation.


<!-- ------------------------------------------------------------------- -->


## Installation

Clone this repository and copy the `.remarkable` folder to your device:
*Caution: the last command will overwrite the files on the device, should they already exist*

```
git clone https://github.com/after-eight/regitable.git
cd regitable
scp -r .regitable/ root@10.11.99.1:
```

ssh into your device

```
ssh root@10.11.99.1

cd ~/.regitable
```


### Edit config

Open the `config` file with `nano` or in the editor of your choice and adjust the variables in the `personal` section to your liking.

If you just want to track your files locally without pushing to a remote repository (yet), simply set the `GIT_REMOTE` to an empty string.
You can add it anytime later.

```
# ----------------------------------------------
# personal
# ----------------------------------------------
GIT_USER="my-name"
GIT_EMAIL="my-email@my-domain.com"
GIT_REMOTE="git@gitlab.com:my-gitlab-name/my-gitlab-repo.git"
```


### Run install script

Start the installation like so

```
source ./config

./install.sh
```

To authenticate your reMarkable against a remote git repository, you have to copy-paste the public ssh key displayed at the end of the installation to your user profile on the server.

```
ssh-rsa AAAAB3NzaC1yc2EAA...
                           ..........
                                     ... root@reMarkable
```

Go to your GitHub/GitLab user profile, to the "ssh keys" section, add a new key and paste inside the public key.


### First commit

To add the status quo of your files to the repository, run:

```
git add -A .
git commit -m "initial commit"
```

If you have a remote configured and already uploaded your public ssh key:

```
git push --set-upstream origin master
```

If this is the first time you connect to your remote from the reMarkable (which is likely), you have to confirm the fingerprint shown by the ssh client to save the host signature to your `known_hosts` file.


#### Enable/disable the service

```
systemctl daemon-reload
systemctl enable --now regitable
```

This will start the service immediately, and on every reboot.


<!-- ------------------------------------------------------------------- -->


## Cloning

Because the `.gitattributes` file is not part of the repository and not checked in (see the reason why in the `Issues` section below), you have to take special care when cloning the repository to your host machine.


#### git-lfs, part I

Of course you need to have git-lfs installed. Follow the instructions for your platform here https://git-lfs.github.com/ to do so. At the end, run

```
git lfs install --local
```

#### ssh key

Make sure you have a public/private key pair to access the server from your host.
You might use the same as the one stored on the reMarkable, but it's better practice to use a dedicated one:

```
ssh-keygen -b 4096
```

Copy the public key to the server, and store the private key locally under a name you like eg. ~/.ssh/me@remarkable2.

If you have multiple projects on a server like github.com or gitlab.com and use different keys on each of them, the best way to distinguish between them is to create a separate entry in the config file like so:

```
Host remarkable2.gitlab.com
  HostName gitlab.com
	Port 22
	User git
	IdentityFile ~/.ssh/me@remarkable2
	IdentitiesOnly yes
```

#### clone, but *DO NOT* checkout yet

Clone your repository, but do not checkout the files yet.
To achieve this, use the `--no-checkout` switch.

Replace the server-part of the ssh-url, that you got from GitHub/GitLab, with the one you created in the config file, eg

```
replace

  git clone --no-checkout git@gitlab.com:...

with

  git clone --no-checkout git@remarkable2.gitlab.com:...
```

This way, git knows which ssh key to use.


#### git-lfs, part II

Create a `.git/info/attributes` file inside the cloned repository and paste the following lines:

```
*.rm filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
*.epub filter=lfs diff=lfs merge=lfs -text
```


#### checkout / pull

Now your repository is ready to be checked out:

```
git checkout master
```

and for future updates simply do

```
git pull
```

<!-- ------------------------------------------------------------------- -->

## Internals


### timezone

The factory setting for the time-zone in my reMarkable was `UTC`.
This led to all my timestamps for my commit messages being UTC as well.

To change the timezone, simply follow the instructions from here: https://remarkablewiki.com/tips/timezone.

In my case, i used the "manual" method:

```
timedatectl set-timezone CET
```


### how it works, inotify, tickets, debounce

(TODO)


### git --git-dir and --work-tree

The notebook files on the reMarkable are stored in `/home/root/.local/share/remarkable/xochitl`, which would also be the place where git would normally place its `.git` folder.
But i was unsure if `xochitl`, or some other service running on the reMarkable, would get upset finding a `.git` directory inside this folder.
So i decided to make use of the very handy `--git-dir` and `--work-tree` options to separate the two.
This way, the data directory stays untouched, and we can place the `.git` directory any place we like.

```
git --git-dir="/home/root/.regitable/.git"  --work-tree="/home/root/.local/share/remarkable/xochitl" init
```


### git and ssh (sshcommand)

I had a hard time getting the dropbear ssh client, which is installed on the reMarkable, to work with my remote repository via ssh.
With openssh, an entry in the `~/.ssh/config` is sufficient to point the client in the right direction.
To persuade the dropbear client to use my ssh key from within a `git push`, i needed to set the `core.sshCommand` in the git config:

```
git config core.sshCommand "ssh -i $GBUP/remote.key"
```


### git lfs

Unfortunately, `git-lfs` is not (yet) available via Entware.
For your convenience, i bundled the arm version from their GitHub releases Page into this repository.

Feel free to check for a more recent version from here: https://github.com/git-lfs/git-lfs/releases.

For the same reason as the `.git` folder, i did not want the `.gitattributes` file to be in the data directory.
Though this means a little more work when cloning (once), to me it feels more solid.


### flock

(TODO)


### inotifywait

(TODO)


### dropbearkey

(TODO)


### systemd

(TODO)


<!-- ------------------------------------------------------------------- -->


## Tools

### GitHub / GitLab

- hosted / on premise (GitLab)
- CI/CD, pipelines, pages

(TODO)


### VSCode

- how to use with GitLens

(TODO)


### Labcoat (GitLab on Android)

(TODO)


### ConnectBot (ssh client on Android)

(TODO)


<!-- ------------------------------------------------------------------- -->


## Issues / Caveats / Limitations


### Memory

The nature of git is to store a copy of every file that was ever committed forever, even if you delete it from the work directory.
It does this in a compressed and efficient way, but still: over time, a git repository will grow and grow and grow.
Plus the additionally needed packages from `entware`, `inotifywait` and of course `git` and `git-lfs` themselves.

Even though i experimented with the device quite excessively: created tons of notebooks, scribbled around, added and deleted pages, renamed, moved and trashed them, my repo size is still far below `40 MB`.
The reMarkable is equipped with `8 GB` of storage, but only time can tell if there will be any memory shortages.

With the help of `git-lfs` and a `git lfs prune` after every push, the storage needed for the copies of the binaries is a small as possible.

But still: the memory of your reMarkable gets halved.


### Integration

The folks at reMarkable seem to be quite open-source friendly, but unfortunately their main application `xochitl` is closed source.
This makes it hard to intercept file changes, and to find the right time to issue a `git add/git commit`.
I use `inotifywait` to watch the data directory for changes, and the package does an amazing job.
But i wished there were at least some "hooks" to interact with `xochitl` directly, as this would make the timing issue much more stable.


### reMarkable Updates

After an OS update on your reMarkable, entware and reGitable will no longer be active, because reMarkable resets everything outside your home directory.

To re-enable both, first run the `entware_reenable.sh` script, and the run `regitable_install.sh` again. Don't worry, it will not overwrite your existing files, but re-install the reGitable service in systemd.


<!-- ------------------------------------------------------------------- -->


## Credits and Links

- [reMarkable.com](https://remarkable.com/)
- [Awesome reMarkable](https://github.com/reHackable/awesome-reMarkable)
- [Git-LFS](https://git-lfs.github.com/)
- [reMarkable Entware](https://github.com/evidlo/remarkable_entware)
- [reMarkable Wiki](https://remarkablewiki.com/start)
- [r/RemarkableTablet on Reddit](https://www.reddit.com/r/RemarkableTablet/)
- [ssh on reMarkable](https://remarkablewiki.com/tech/ssh)


<!-- ------------------------------------------------------------------- -->


## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
