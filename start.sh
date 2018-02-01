#!/bin/bash

# Variables
RECADR=$ADDRESS
COUNT=0
C=1
MAIN_LOG="../HTMLCOIN-Logs/htmlcoin-miner-main.log"

# Functions
start_daemon(){
  /usr/local/bin/htmlcoind --daemon --rpcthreads=$MINERS
}

check_daemon(){
  echo -ne "Blocks synced: 0/?"\\r

  while true; do
    MONEY="$(/usr/local/bin/htmlcoin-cli getinfo > /dev/null 2>&1)"
    RETVAL="$?"
    if [ $RETVAL -ne "0" ]
    then
      sleep 5
      continue
    else
      break
    fi
  done

  while true; do
    # Get chain height
    HEIGHT="$(/usr/local/bin/htmlcoin-cli getcheckpoint | grep height | awk '{ print $2 }')"
    HEIGHT="${HEIGHT:: -1}"

    # We add 6 here just because usually the height returned by getcheckpoint is 6 blocks behind
    TRUE_HEIGHT_ESTIMATE=$(($HEIGHT + 6))

    # Get number of processed blocks
    BLOCKS="$(/usr/local/bin/htmlcoin-cli getblockcount)"

    if [ $HEIGHT -eq "0" ]
    then
      echo -ne "Blocks synced: $BLOCKS/?"\\r
      sleep 5
      continue
    fi

    echo -ne "Blocks synced: $BLOCKS/$TRUE_HEIGHT_ESTIMATE"\\r

    if [ $BLOCKS -lt $HEIGHT ]
    then
      sleep 5
      continue
    else
      break
    fi
  done

  echo
  echo
  echo "Connections must equal 8 to continue with mining... Please wait..."
  while true; do
    CONNECTIONS="$(/usr/local/bin/htmlcoin-cli getinfo | grep connections | awk '{ print $2 }')"
    CONNECTIONS="${CONNECTIONS:: -1}"
    echo "Connections = $CONNECTIONS"
    if [ $CONNECTIONS -lt "8" ]
    then
      sleep 10
      continue
    else
      break
    fi
  done

}

start_mining(){
  while true; do
    shopt -s lastpipe
    /usr/local/bin/htmlcoin-cli generatetoaddress 100 $RECADR 88888888 | readarray -t BLOCK
    { echo "$2   Block Count:$C   $(date)" & echo "Block Output: ${BLOCK[@]}"; } | tac | tee -a $1 $MAIN_LOG > /dev/null
    (( C++ ))
  done &
}

# Entrypoint...

# Set up logging directory if it is not already there.
mkdir -p ../HTMLCOIN-Logs

# Remove any previous log files that may have been left from a previous mining session.
rm -f ../HTMLCOIN-Logs/*

touch $MAIN_LOG

start_daemon

# Visual check to make sure the daemon is in sync.
echo "Checking that the daemon is in sync. Please wait!"
echo
check_daemon
echo
echo "Please wait while the miners are started!"
echo

while [ $COUNT -lt $MINERS ]
do
  touch ../HTMLCOIN-Logs/htmlcoin-miner-$COUNT.log
  start_mining ../HTMLCOIN-Logs/htmlcoin-miner-$COUNT.log Miner-$COUNT
  (( COUNT++ ))
  sleep 2
done

if [ -z ${TELEGRAM_BOT_TOKEN+x} ] || [ -z ${TELEGRAM_CHAT_ID+x} ]
then
  echo -e "\e[1m\e[92mStart up complete! Now we will just watch and hope we'll find some block :)\e[0m"
  echo

  tail -f ../HTMLCOIN-Logs/htmlcoin-miner-main.log | grep --line-buffered -B 1 '"'
else
  echo -e "\e[1m\e[92mStart up complete! Now we will just watch and hope we'll find some block :) (Telegram notifications are active)\e[0m"
  echo

  tail -f ../HTMLCOIN-Logs/htmlcoin-miner-main.log | grep --line-buffered -B 1 '"' | while read line; do curl -g -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage?chat_id=$TELEGRAM_CHAT_ID&text=$line" && echo; done
fi
