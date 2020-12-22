SCRIPT=$(dirname $(realpath -s $0))
source $SCRIPT/config.sh

function git_commit() {
  uuid=$1
  date_now=$(printf '%(%F %T)T' $date)

  if [[ $uuid == "trash" ]]; then

    /opt/bin/git --git-dir=$GIT add `/opt/bin/git --git-dir=$GIT ls-files --deleted`

    message="$date_now - trash"

  elif [[ -f $DATA/$uuid.metadata ]]; then
    metadata=$(cat $DATA/$uuid.metadata)

    test=$(echo $metadata | tr '\n' '_' | sed s/^\{.*lastModified.*version.*visibleName.*\}_$/OK/)

    if [[ $test == "OK" ]]; then

      lastModified=$( echo $metadata | grep '"lastModified":' | sed 's/^.*"lastModified": "//'  | sed 's/" }.*//' )
      visibleName=$(  echo $metadata | grep '"visibleName":'  | sed 's/^.*"visibleName": "//'   | sed 's/" }.*//' )
      version=$(      echo $metadata | grep '"version":'      | sed 's/^.*"version": //'        | sed 's/,.*//'   )

      lastModified10=${lastModified:0:10}

      date_mod=$(printf '%(%F %T)T' $lastModified10)

      message="$date_now - $visibleName - m:$date_mod"

      /opt/bin/git --git-dir=$GIT add "*/$uuid*"
    fi
  fi

  staged=$(/opt/bin/git --git-dir=$GIT diff --staged --name-only | wc -l)

  if (( $staged > 0 )); then
    /opt/bin/git --git-dir=$GIT commit -q -m "$message"
  fi
}

function git_push() {
  if [[ $GIT_REMOTE != "" ]]; then
    committed=$(/opt/bin/git --git-dir=$GIT log origin/master..master --name-only | wc -l)

    if (( $committed > 0 )); then

      if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        /opt/bin/git --git-dir=$GIT push -q
      fi
    fi
  fi
}

# only allow one instance of this script
flock -n $GIT_LOCK || exit 0

count=30

while (( $count > 0 )); do

  flock -x $TICKET_LOCK || exit 1

  # get oldest ticket
  ticket=$(ls $TICKET -tr1 | head -n 1)
  uuid="sleep"

  # no more tickets, then push and exit
  if [[ $ticket == "" ]]; then
    git_push
    exit 0
  fi

  # get stamp from ticket
  stamp=$(cat $TICKET/$ticket)
  now=$(date +%s)
  let diff=$now-$stamp

  # debounce period over, then go
  if (( $diff > 2 )); then
    rm $TICKET/$ticket
    uuid=$ticket
  fi

  flock -u $TICKET_LOCK

  if [[ $uuid == "sleep" ]]; then
    sleep 1s
  else
    git_commit $uuid
  fi

  let count=$count-1

done
