# reGitable - backup your reMarkable using git

# [<img src="regitable.png"></p>](https://github.com/after-eight/regitable)

## Objective

Most of my digital life is stored in a git repository, so the first thing i thought of when i examined my newly arrived reMarkable2: can i install and use git on it?

The filesystem layout of the reMarkable meets the requirements for a git repository pretty well.
Besides the binary `.rm` files, all other files are more or less json-formatted text files.
Plus, the filenames are immutable uuids, so even if you rename a notebook or move it from one folder to another, all that changes is the `parent` entry in the `.metadata` file.
`.rm` files don't grow _that_ large, because it's one file per page.
And even though they are binary: unless you do heavy cut-and-paste operations, their content changes in a way that git can handle efficiently.

By pushing changes to a remote repository instantly, i do not only have a backup of all my notebooks in the cloud.
The repository contains all the back-versions of my files, and should i need to return to a long ago previous stage of a file, or recover a deleted file, i can simply check it out of my repository and re-upload it onto my remarkable.

If you're a little paranoid like me, simply install a privately hosted GitLab instance, and all your files are completely under your control.


<!-- ------------------------------------------------------------------- -->


## Prerequisites

### Entware

Before you can install and use reGitable, you have to install [reMarkable Entware](https://github.com/evidlo/remarkable_entware)!

The installation is very easy and straight forward, thanks to Evan Widloski at this point.


### Remote Repository

Both GitHub and GitLab offer private repos for free, which is the easiest way to get started. Simply create a new repository (leave it empty, do not create a `README.md` file), upload the public ssh key that is created for you during the installation of reGitable, and you are ready to go.

To increase privacy, you can use an on-premise GitLab installation.


<!-- ------------------------------------------------------------------- -->


## Installation

On your host machine, clone this repository:

```
git clone https://github.com/after-eight/regitable.git
cd regitable
```

Open the file `regitable_install.sh` in the editor of your choice and adjust the variables in the `personal` section to your liking. Leave the variables in the `environment` section as is, or adjust if needed.

If you just want to track your files locally without pushing to a remote repository, simply set the `GIT_REMOTE` to an empty string.

```
# ----------------------------------------------
# personal
# ----------------------------------------------
GIT_USER="my-name"
GIT_EMAIL="my-email@my-domain.com"
GIT_REMOTE="git@github.com:my-github-name/my-github-repo.git"

# ----------------------------------------------
# environment
# ----------------------------------------------
HOME="/home/root"
WORK="$HOME/.local/share"
DATA="$WORK/remarkable/xochitl"

GBUP="$HOME/.regitable"
GIT="$GBUP/.git"
TICKET="$GBUP/ticket"

SERVICE="regitable"

GIT_LOCKFILE="$GBUP/git.lock"
TICKET_LOCKFILE="$GBUP/ticket.lock"
```


Connect your reMarkable via USB and copy the files to your device:

```
scp regitable_install.sh root@10.11.99.1:
scp _monitor.sh root@10.11.99.1:
scp _acp.sh root@10.11.99.1:
```

Run the install script:

```
ssh root@10.11.99.1 ./regitable_install.sh
```

To authenticate your reMarkable against a remote git repository, you have to add the public ssh key displayed at the end of the installation to your user profile on the server.

```
ssh-rsa AAAAB3NzaC1yc2EAA.....
```


<!-- ------------------------------------------------------------------- -->


```
cd .regitable
git add -A .
git commit -m "initial commit"
```

If you have a remote configured:

```
git push
```



## Usage

To issue these commands, ssh into your device.

### reload service files

This is recommended after you installed/changed a service file.

```
systemctl daemon-reload
```


### Enable/disable the service

```
systemctl enable regitable
systemctl disable regitable
```

alternatively, enable _and_ start at once

```
systemctl enable --now regitable
```

After you have enabled the service, it will start automatically on the next reboot.

### Start/stop the service

```
systemctl start regitable
systemctl stop regitable
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


### git --branch --set-upstream-to origin/master

Before you can push to a remote repository, you have to
- add a remote
- specify the upstream

A remote is added via the `git remote add` command, and has to be done in advance.
As for the upstream, git requires you to specify it on your first push with the `--upstream` option. To avoid this, you can set it in advance using the `--set-upstream-to` option:

```
git branch --set-upstream-to origin/master
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
This would definitely help reducing the size of the local repository, by telling it to track `.rm` files.

As an experiment, i downloaded the ARM32 version of git-lfs and copied it to the reMarkable.
This seems to work just fine.
The downsides actually are the size of git-lfs itself (around 10 MB), and the fact that the `.gitattributes` file has to reside inside the work-tree, which i want to keep clean.

In addition, my knowledge on how to identify and install dependencies needed by a package like git-lfs is very limited, so i decided to abandon this approach.
Any help greatly appreciated.


### flock

(TODO)


### inotifywait

(TODO)


### dropbearkey

(TODO)


### systemd

(TODO)




## Tools

### (TODO) GitHub / GitLab

- hosted / on premise (GitLab)
- CI/CD, pipelines, pages


### (TODO) Labcoat

(GitLab on Android)


<!-- ------------------------------------------------------------------- -->



### (TODO) Labcoat

(GitLab on Android)


### (TODO) ConnectBot

(ssh client on Android)



## Caveats / Limitations

### Memory

The nature of git is to store a copy of every file that was ever committed forever, even if you delete it from the work directory.
It does this in a compressed and efficient way, but still: over time, a git repository will grow and grow and grow.
Plus the additionally needed packages from `entware`, `inotifywait` and of course `git` itself.

Even though i experimented with the device quite excessively: created tons of notebooks, scribbled around, added and deleted pages, renamed, moved and trashed them, my repo size is still far below `40 MB`.
The reMarkable is equipped with `8 GB` of storage, but only time can tell if there will be any memory shortages.

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
- [reMarkable Entware](https://github.com/evidlo/remarkable_entware)
- [reMarkable Wiki](https://remarkablewiki.com/start)
- [r/RemarkableTablet on Reddit](https://www.reddit.com/r/RemarkableTablet/)
- [ssh on reMarkable](https://remarkablewiki.com/tech/ssh)


<!-- ------------------------------------------------------------------- -->


## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
