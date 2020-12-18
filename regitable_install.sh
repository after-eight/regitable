#!/bin/bash

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


# ----------------------------------------------
# exit on errors
# ----------------------------------------------
set -e


# ----------------------------------------------
# check for entware, stop if not installed
# ----------------------------------------------
if [ ! -f /opt/bin/opkg ]; then
  echo "Install entware for reMarkable first: https://github.com/Evidlo/remarkable_entware"
  exit
fi


# ----------------------------------------------
# check entware packages, install if needed
# ----------------------------------------------
[ ! -f /opt/bin/inotifywait ] && /opt/bin/opkg install inotifywait
[ ! -f /opt/bin/git ] && /opt/bin/opkg install git


# ----------------------------------------------
# check reGitable directories, create if neeeded
# ----------------------------------------------
[ ! -d $GBUP ] && mkdir $GBUP
[ ! -d $TICKET ] && mkdir $TICKET


# ----------------------------------------------
# check remote ssh key, create if neeeded
# ----------------------------------------------
[ ! -f $GBUP/remote.key ] && \
  dropbearkey -t rsa -f $GBUP/remote.key | grep "^ssh-rsa" > $GBUP/remote.key.pub


# ----------------------------------------------
# check .git directory, init repo if neeeded
# ----------------------------------------------
if [ ! -d $GIT ]; then
  /opt/bin/git --git-dir=$GIT --work-tree $WORK init

  /opt/bin/git --git-dir=$GIT config user.name "$GIT_USER"
  /opt/bin/git --git-dir=$GIT config user.email "$GIT_EMAIL"

  cat >>$GIT/info/exclude <<EOF
*.lock
*.zip
*.uploading
*.tmp
*.temp
*.pdf
*.epub
EOF

  /opt/bin/git --git-dir=$GIT config core.sshCommand "ssh -i $GBUP/remote.key"

  if [[ $GIT_REMOTE != ""]]; then
    /opt/bin/git --git-dir=$GIT remote add origin $GIT_REMOTE
    /opt/bin/git --git-dir=$GIT branch --set-upstream-to origin/master
  fi

fi


# ----------------------------------------------
# check for config.sh, create if needed
# ----------------------------------------------
if [ ! -f $GBUP/config.sh ]; then

  cat >$GBUP/config.sh <<EOF
HOME=$HOME
GBUP=$GBUP
GIT=$GIT
TICKET=$TICKET

WORK=$WORK
DATA=$DATA

exec {GIT_LOCK}>$GIT_LOCKFILE
exec {TICKET_LOCK}>$TICKET_LOCKFILE
EOF

fi


# ----------------------------------------------
# check script files, create if needed
# ----------------------------------------------
if [ ! -f $GBUP/monitor.sh ]; then
  if [ ! -f ./_monitor.sh ]; then
    echo "ERROR: missing _monitor.sh"
    exit 1
  fi

  cat > $GBUP/monitor.sh <<EOF
#!/bin/bash
source $GBUP/config.sh
EOF

  cat ./_monitor.sh >> $GBUP/monitor.sh
  chmod +x $GBUP/monitor.sh
fi

if [ ! -f $GBUP/acp.sh ]; then

  if [ ! -f ./_acp.sh ]; then
    echo "ERROR: missing _acp.sh"
    exit 1
  fi

  cat >$GBUP/acp.sh <<EOF
#!/bin/bash
source $GBUP/config.sh
EOF

  cat ./_acp.sh >> $GBUP/acp.sh
  chmod +x $GBUP/acp.sh
fi


# ----------------------------------------------
# check reGitable service file, create if needed
# ----------------------------------------------
if [ ! -f /etc/systemd/system/$SERVICE.service ]; then

  cat >/etc/systemd/system/$SERVICE.service <<EOF
[Unit]
Description=reGitable
After=home.mount opt.mount

[Service]
ExecStart=$GBUP/monitor.sh

[Install]
WantedBy=multi-user.target
EOF

fi


# ----------------------------------------------
# epilogue
# ----------------------------------------------
echo
echo "SUCCESS - reGitable (re)installed successfully."
echo
echo "To be able to push to your remote git repository via ssh,"
echo "add the following public key to your user-profile."
echo
cat $GBUP/remote.key.pub
echo
echo "To enable and/or start the service, use:"
echo "  systemctl daemon-reload"
echo "  systemctl enable --now $SERVICE"
echo
echo "For further information, visit https://github.com/after-eight/regitable"
