#!/bin/bash

SCRIPT=$(dirname $(realpath -s $0))
source $SCRIPT/config.sh


# ----------------------------------------------
# exit on errors
# ----------------------------------------------
set -e


# ----------------------------------------------
# check for existing config, load if found
# ----------------------------------------------
[ -f $GBUP/config.sh ] && source $GBUP/config.sh


# ----------------------------------------------
# check for entware, EXIT if not installed
# ----------------------------------------------
if [ ! -f /opt/bin/opkg ]; then
  echo "ERROR: missing Entware for reMarkable."
  echo "Install from here: https://github.com/Evidlo/remarkable_entware"
  exit 1
fi


# ----------------------------------------------
# check script files, EXIT if missing
# ----------------------------------------------
if [ ! -f $GBUP/monitor.sh ]; then
  echo "ERROR: missing monitor.sh"
  exit 1
fi
chmod +x $GBUP/monitor.sh

if [ ! -f $GBUP/acp.sh ]; then
  echo "ERROR: missing acp.sh"
  exit 1
fi
chmod +x $GBUP/acp.sh


# ----------------------------------------------
# check entware packages, install if needed
# ----------------------------------------------
[ ! -f /opt/bin/inotifywait ] && opkg install inotifywait
[ ! -f /opt/bin/git ] && opkg install git


# ----------------------------------------------
# check git-lfs package, install if needed
# ----------------------------------------------
[ ! -f /opt/bin/git-lfs ]; then
  echo "Installing git-lfs...this may take a while..."
  curl -s https://api.github.com/repos/git-lfs/git-lfs/releases/latest \
  | grep "browser_download_url.*-arm-" \
  | cut -d : -f 2,3 \
  | tr -d \" \
  | xargs curl -L --output $GBUP/git-lfs.tar.gz

  tar -zxf $GBUP/git-lfs.tar.gz -C /opt/bin/ git-lfs
  chmod +x /opt/bin/git-lfs

  rm $GBUP/git-lfs.tar.gz
fi


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

  git --git-dir=$GIT --work-tree=$WORK init

  git lfs install --local --skip-smudge

  git config user.name "$GIT_USER"
  git config user.email "$GIT_EMAIL"

  git config core.sshCommand "ssh -i $GBUP/remote.key"

  if [[ $GIT_REMOTE ]]; then
    git remote add origin $GIT_REMOTE
  fi

  cat > $GIT/info/exclude <<EOF
*.lock
*.zip
*.uploading
*.tmp
*.temp
EOF

  cat > $GIT/info/attributes <<EOF
*.rm filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
*.epub filter=lfs diff=lfs merge=lfs -text
EOF

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
