# reGitable - backup your reMarkable using git



## Objective

Most of my digital life is stored in a git repository, so the first thing i thought of when i examined my newly arrived reMarkable2: can i install and use git on it?

The filesystem layout of the reMarkable meets the requirements for a git repository pretty well.
Besides the binary `.rm` files, all other files are more or less json-formatted text files.
Plus, the filenames are immutable uuids, so even if you rename a notebook or move it from one folder to another, all that changes is the `parent` entry in the `.metadata` file.
`.rm` files don't grow _that_ large, because it's one file per page.
And even though they are binary: unless you do heavy cut-and-paste operations, their content changes in a way that git can handle efficiently.

The notebook files on the reMarkable are stored in `/home/root/.local/share/remarkable/xochitl`, which would also be the place where git would normally place its `.git` folder.
But i was unsure if `xochitl`, or some other service running on the reMarkable, would get upset finding a `.git` directory inside this folder.
So i decided to make use of the very handy `--work-tree` option to separate the two.
This way, the data directory stays untouched, and we can place the `.git` directory any place we like.



## Prerequisites

Before you can install and use `reGitable`, you have to install [reMarkable Entware](https://github.com/evidlo/remarkable_entware)!

The installation is very easy and straight forward, thanks to Evan Widloski at this point.



## Installation

On your host machine, clone the repository:

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
GIT_REMOTE="git@github.com:my-github-name/my-githup-repo.git"

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



## First commit

If you want to issue an initial commit to backup the "status quo", you can issue the following commands.
If you just want to add new notebooks and changes to existing ones from now on, you can skip this section.

ssh into your device and issue the following commands:

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



## (TODO) Internals

- how it works, inotify, tickets, debounce
- git and ssh (sshcommand)
- timezone
- flock



## Tools

### (TODO) GitHub / GitLab

- hosted / on premise (GitLab)
- CI/CD, pipelines, pages


### (TODO) Labcoat
(GitLab on Android)

TODO

### (TODO) VSCode

TODO (how to use with GitLens)



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



## Credits and Links

- [reMarkable.com](https://remarkable.com/)
- [Awesome reMarkable](https://github.com/reHackable/awesome-reMarkable)
- [reMarkable Entware](https://github.com/evidlo/remarkable_entware)
- [reMarkable Wiki](https://remarkablewiki.com/start)
- [r/RemarkableTablet on Reddit](https://www.reddit.com/r/RemarkableTablet/)
- [ssh on reMarkable](https://remarkablewiki.com/tech/ssh)



## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
