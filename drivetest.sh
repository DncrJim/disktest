#!/bin/bash

#notes:
#single incoming variable for drive name (sdxx)
#requires: smartctl, badblocks, zfs
#overwrites existing .log file

#if there's no variable, throw error
if [ -z "$1" ]
  then
  echo "missing argument"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi

#if variable is greater than 4 or less than 3 chars, throw error
if [[ ${#1} > 4 || ${#1} < 3 ]]
  then
  echo "incorrect syntax"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi


#if variable $1 does not begin with first two chars "sd", throw error
if [[ "sd" != "${1:0:2}" ]]
  then
  echo "incorrect syntax"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi

#pull parameter from command line, assign to variable
SDXX=$1

#insert other misc variables
EMAIL=root
SEND_EMAIL=1    # 0 = no emails, 1 = email status updates, 2 = email full log
DIR=$HOME       #location of save files (directory must exist) "" for / (unconfirmed)


#######  START INITIATE

echo "******  Status Before Testing ******" > $DIR/$SDXX.log    #note: overwrites existing file
echo "" > $DIR/$SDXX.log

#activate S.M.A.R.T. just in case it isn't and print initial drive info to log file
smartctl -s on -H -i -A -l error -l selftest/dev/$SDXX >> $DIR/$SDXX.log

      #email
      if [ SEND_EMAIL > 0 ]; then echo $DIR/$SDXX.log | mail -s "$SDXX drivetest status initial" $EMAIL; fi

#######  START SHORT test

#run short smart test
smartctl -t short /dev/$SDXX >> $DIR/$SDXX.log

      #wait for output of smartctl to indicate that test has completed
      until ! smartctl -a /dev/$SDXX | grep -c "progress" > /dev/null; do sleep 10; done

echo "******  Status After Short Smart Test ******" >> $DIR/$SDXX.log
echo "" > $DIR/$SDXX.log
smartctl -l selftest /dev/$SDXX >> $DIR/$SDXX.log

      #email
      if [ SEND_EMAIL = 1 ]; then echo smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status short test" $EMAIL; fi
      if [ SEND_EMAIL = 2 ]; then echo $DIR/$SDXX.log | mail -s "$SDXX drivetest status short test" $EMAIL; fi

#######  START LONG test

#run long smart test
smartctl -t long /dev/$SDXX >> $DIR/$SDXX.log

      #wait for output of smartctl to indicate that test has completed
      until ! smartctl -a /dev/$SDXX | grep -c "progress" > /dev/null; do sleep 60; done

echo "******  Status After Long Smart Test ******" >> $DIR/$SDXX.log
echo "" > $DIR/$SDXX.log
smartctl -l selftest /dev/$SDXX >> $DIR/$SDXX.log

      #email
      if [ SEND_EMAIL = 1 ]; then echo smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status long test" $EMAIL; fi
      if [ SEND_EMAIL = 2 ]; then echo $DIR/$SDXX.log | mail -s "$SDXX drivetest status long test" $EMAIL; fi


echo "******  Smart Tests Complete ******" >> $DIR/$SDXX.log
echo "" > $DIR/$SDXX.log



exit 0
