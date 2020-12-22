SCRIPT=$(dirname $(realpath -s $0))
source $SCRIPT/config

if [[ $GBUP == "" ]]; then
  echo "Environment variables are missing! Make sure this file was created"
  echo "through the 'gbup_install.sh' script. It will make sure the config.sh"
  echo "file is present, and is included via source config.sh"
  exit 1
fi

/opt/bin/inotifywait -m -q --format '%f' -e DELETE $DATA | \
while read FILE
do
  uuid=""

  if [[ $FILE == *".lock" ]]; then
    uuid=${FILE%.lock}
  elif [[ $FILE == *".uploading" ]]; then
    uuid=${FILE%.uploading}

    # remove trailing _xx where xx is a number
    uuid=$(echo $uuid | sed 's/_.*$//')
  fi

  # test uuid for correct format (excludes "trash" etc)
  test=$(echo $uuid | sed 's/^........-....-....-....-............$/OK/')

  if [[ $uuid == "trash" || $test == "OK" ]]; then

    flock -x $TICKET_LOCK
    echo `date +%s` > $TICKET/$uuid
    flock -u $TICKET_LOCK

    $GBUP/acp.sh &
  fi

done
