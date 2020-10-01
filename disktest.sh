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
SEND_EMAIL=1      # 0 = no emails, 1 = email status updates, 2 = email full log
DIR=$HOME         #location of save files (directory must exist) "" for / (unconfirmed)
BACKGROUND=0      # 0 = run in foreground, 1 = run in background (not yet implimented)
RUN_SMART_S=0     # 0 = skip, otherwise run
RUN_SMART_L=0     # 0 = skip, otherwise run
RUN_BADBLOCKS=0   # 0 = skip, otherwise run
SPEED_TEST=1      # 0 = skip, otherwise run

#insert warning for disk overwrite if badblocks = 1

#######  START INITIATE

#note: the following line overwrites any existing file
echo "******  Status Before Testing ******" | tee $DIR/$SDXX.log; echo "" | tee $DIR/$SDXX.log

#activate S.M.A.R.T. just in case it isn't and print initial drive info to log file
smartctl -s on -H -i -A -l error -l selftest /dev/$SDXX | tee -a $DIR/$SDXX.log

      #email
      if [ SEND_EMAIL > 0 ]; then mail -s "$SDXX drivetest status initial" $EMAIL < $DIR/$SDXX.log; fi

if [[ $RUN_SMART_S == 0 ]]
    then echo "****** Skipping Short Test ******"; echo ""  | tee -a $DIR/$SDXX.log
    else
      echo "****** Starting Short Test ******"; echo ""  | tee -a $DIR/$SDXX.log

      smartctl -t short /dev/$SDXX | tee -a $DIR/$SDXX.log

                #create file for while to watch for test to be complete
                smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp

                #add padding before progress counter
                echo ""; echo ""

                #wait for output of smartctl to indicate that test has completed
                while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                  do
                    echo -e "\r\033[1A\033[1A\033[0K"
                    smartctl -a /dev/$SDXX | grep "remaining"
                    smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp
                    sleep 5
                  done

                  #clean up
                  rm $DIR/$SDXX.tmp

                  #add padding after progress counter
                  echo ""; echo ""


      echo "******  Status After Short Smart Test ******" | tee -a $DIR/$SDXX.log; echo "" | tee -a $DIR/$SDXX.log
      smartctl -l selftest /dev/$SDXX | tee -a $DIR/$SDXX.log

            #email
            if [ SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status short test" $EMAIL; fi
            if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX drivetest status short test" $EMAIL < $DIR/$SDXX.log; fi

fi
if [[ $RUN_SMART_L == 0 ]]
    then echo "****** Skipping Long Test ******"; echo ""  | tee -a $DIR/$SDXX.log
    else
      echo "****** Starting Long Test ******"; echo ""

      smartctl -t long /dev/$SDXX | tee -a $DIR/$SDXX.log

                  #create file for while to watch for test to be complete
                  smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp

                  #add padding before progress counter
                  echo ""; echo ""

                  #wait for output of smartctl to indicate that test has completed
                  while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                    do
                      echo -e "\r\033[1A\033[1A\033[0K"
                      smartctl -a /dev/$SDXX | grep "remaining"
                      smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp
                      sleep 60
                    done

                  #clean up
                  rm $DIR/$SDXX.tmp

                  #add padding after progress counter
                  echo ""; echo ""

      echo "******  Status After Long Smart Test ******" | tee -a $DIR/$SDXX.log; echo "" | tee -a $DIR/$SDXX.log
      smartctl -l selftest /dev/$SDXX | tee -a $DIR/$SDXX.log

      echo "******  Smart Tests Complete ******" | tee -a $DIR/$SDXX.log; echo "" | tee -a $DIR/$SDXX.log

            #email
            if [ SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status long test" $EMAIL; fi
            if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX drivetest status long test" $EMAIL < $DIR/$SDXX.log; fi
fi
if [[ $RUN_BADBLOCKS == 0 ]]
    then echo "****** Skipping Badblocks ******"; echo "" | tee -a $DIR/$SDXX.log
    else
      echo "****** Starting Badblocks ******"; echo "" | tee -a $DIR/$SDXX.log

#for some reason the output of badblocks is not going to the log file

      badblocks -b 4096 -wsv /dev/$SDXX | tee -a $DIR/$SDXX.log

      echo "******  Badblocks Complete, running Short Test ******" | tee -a $DIR/$SDXX.log; echo "" | tee -a $DIR/$SDXX.log

        smartctl -t short /dev/$SDXX | tee -a $DIR/$SDXX.log

                  #create file for while to watch for test to be complete
                  smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp

                  #add padding before progress counter
                  echo ""; echo ""

                  #wait for output of smartctl to indicate that test has completed
                  while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                    do
                      echo -e "\r\033[1A\033[1A\033[0K"
                      smartctl -a /dev/$SDXX | grep "remaining"
                      smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp
                      sleep 5
                    done

                    #clean up
                    rm $DIR/$SDXX.tmp

                    #add padding after progress counter
                    echo ""; echo ""

      echo "******  Status After Badblocks ******" | tee -a $DIR/$SDXX.log; echo "" | tee -a $DIR/$SDXX.log

      smartctl -s on -H -i -A -l error -l selftest /dev/$SDXX | tee -a $DIR/$SDXX.log

            if [ SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status after badblocks" $EMAIL; fi
            if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX drivetest status after badblocks" $EMAIL < $DIR/$SDXX.log; fi

fi

if [[ $SPEED_TEST == 0 ]]

## dd also does not output results to log

    then echo "****** Skipping r/w Speed Test ******"; echo "" | tee -a $DIR/$SDXX.log
    else
      echo "****** Starting r/w Speed Test ******"; echo "" | tee -a $DIR/$SDXX.log

      echo "1G file size speed test"
      dd if=/dev/zero of=/dev/$SDXX bs=1G count=4 oflag=dsync | tee -a $DIR/$SDXX.log
      echo ""
      echo "64M file size speed test"
      dd if=/dev/zero of=/dev/$SDXX bs=64M count=128 oflag=dsync | tee -a $DIR/$SDXX.log
      echo ""
      echo "1M file size speed test"
      dd if=/dev/zero of=/dev/$SDXX bs=1M count=4k oflag=dsync | tee -a $DIR/$SDXX.log
      echo ""
      echo "8K file size speed test"
      dd if=/dev/zero of=/dev/$SDXX bs=8k count=8k oflag=dsync | tee -a $DIR/$SDXX.log
      echo ""
      echo "512B file size speed test"
      dd if=/dev/zero of=/dev/$SDXX bs=512 count=1000 oflag=dsync | tee -a $DIR/$SDXX.log


      if [ SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX drivetest status after badblocks" $EMAIL; fi
      if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX drivetest status after badblocks" $EMAIL < $DIR/$SDXX.log; fi

fi
exit 0
