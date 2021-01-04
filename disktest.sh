#!/bin/bash

#notes:
#single incoming variable for drive name (sdxx)
#requires: smartctl, badblocks, zfs
#overwrites existing .log file when it starts

# it is suggested to run tool once first with just -d <disk> to confirm that the smart tests do not require any additional information


#insert other variables (selections may be overwritten by flags below)
ERASE_IT_ALL="n"  #sets erase to no
DIR=""            #location of save files (directory must exist), $HOME will be root home (I think?), "" for / (unconfirmed)
BACKGROUND=0      # 0 = run in foreground, 1 = run in background (not yet implimented)
RUN_SMART_S=0     # 1 = run
RUN_SMART_L=0     # 1 = run
RUN_BADBLOCKS=0   # 1 = run
RUN_SPEED_TEST=0  # 1 = run
RUN_ZFS_TEST=0    # 1 = run
SEND_EMAIL=1      # 0 = no emails, 1 = email status updates, 2 = email full log each time
EMAIL="root"

#import flags and save to variables
  #flags override settings saved above
while getopts ybaslbwzm:e:d: option
do
  case "${option}"
    in
    y) ERASE_IT_ALL="y" ;;
    a) RUN_ALL=1;;
    s) RUN_SMART_S=1 ;;
    l) RUN_SMART_L=1 ;;
    b) RUN_BADBLOCKS=1 ;;
    w) RUN_SPEED_TEST=1 ;;
    z) echo "you've used an unavailable feature; goodbye." ; exit 1 ;;
    m) SEND_EMAIL=${OPTARG} ;;
    e) EMAIL=${OPTARG} ;;
    d) DISK=${OPTARG} ;;
  esac
done

#test device name variable
if [ -z "$DISK" ] ; then echo "missing argument" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if there's no variable, throw error
if [[ ${#DISK} > 4 || ${#DISK} < 3 ]] ; then echo "incorrect syntax" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if variable $1 is greater than 4 or less than 3 chars, throw error
if [[ "sd" != "${DISK:0:2}" ]] ; then echo "incorrect syntax" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if variable $1 does not begin with first two chars "sd", throw error

#pull parameter from command line, assign to variable
SDXX=$DISK

#test to make sure flags have not created conflict
if [[ $RUN_ALL == 1 ]] ; then
    if [[ $RUN_SMART_S == 1 ]] || [[ $RUN_SMART_L == 1 ]] || [[ $RUN_BADBLOCKS == 1 ]] || [[ $RUN_SPEED_TEST == 1 ]] || [[ $RUN_ZFS_TEST == 1 ]] ; then
      echo "the chosen flags conflict; goodbye." ; exit 1
    else
      RUN_SMART_S=1 ; RUN_SMART_L=1 ; RUN_BADBLOCKS=1 ; RUN_SPEED_TEST=1 ; RUN_ZFS_TEST=1
    fi
fi

#insert warning for disk overwrite if badblocks = 1
if [[ $RUN_BADBLOCKS == 1 ]] || [[ $RUN_SPEED_TEST == 1 ]] || [[ $RUN_ZFS_TEST == 1 ]]
 then
    while [[ $ERASE_IT_ALL != "y" ]]
      do
        echo -n "Are you sure you are willing to lose any/all data on /dev/$SDXX? (y/n): "
        read ERASE_IT_ALL
          if [[ $ERASE_IT_ALL == "n" ]] ; then echo "goodbye." ; exit 1
          elif [[ $ERASE_IT_ALL != "y" ]] ; then echo "I don't understand your response.."
          fi
      done
  fi

#insert code to stop testing if no tests have been selected
if [[ $RUN_SMART_S -eq 0 ]] && [[ $RUN_SMART_L -eq 0 ]] && [[ $RUN_BADBLOCKS -eq 0 ]] && [[ $RUN_SPEED_TEST -eq 0 ]] && [[ $RUN_ZFS_TEST -eq 0 ]]
  then echo "no tests selected; goodbye." ; exit 1
 fi

#insert code to run in background if BACKGROUND = 1

######################################
#######  MAIN BODY OF TESTING

#note: the following line overwrites any existing file
echo "******  Status Before Testing ******" |& tee $DIR/$SDXX.log; echo "" |& tee $DIR/$SDXX.log

#activate S.M.A.R.T. just in case it isn't and print initial drive info to log file
smartctl -s on -H -i -A -l error -l selftest /dev/$SDXX |& tee -a $DIR/$SDXX.log

      #email
      if [ $SEND_EMAIL > 0 ]; then mail -s "$SDXX disktest status initial" $EMAIL < $DIR/$SDXX.log; fi

if [[ $RUN_SMART_S == 1 ]]
    then echo "****** Starting Short Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

    smartctl -t short /dev/$SDXX |& tee -a $DIR/$SDXX.log

              smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp     #create file for while to watch for test to be complete
              echo ""; echo "" |& tee -a $DIR/$SDXX.log   #add padding before progress counter

              #wait for temp file to not contain "progress", indicating that test has completed
              while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                do
                  echo -e "\r\033[1A\033[1A\033[0K" |& tee -a $DIR/$SDXX.log
                  smartctl -a /dev/$SDXX | grep "remaining" |& tee -a $DIR/$SDXX.log
                  smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp   #update file for 'while' to watch for test to be complete
                  sleep 5
                done

                rm $DIR/$SDXX.tmp                           #clean up
                echo -e "\r\033[1A\033[1A\033[0K" |& tee -a $DIR/$SDXX.log   #remove progress counter

    echo "******  Status After Short Smart Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
    smartctl -l selftest /dev/$SDXX |& tee -a $DIR/$SDXX.log

          #email
          if [ $SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX disktest status after short test" $EMAIL; fi
          if [ $SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after short test" $EMAIL < $DIR/$SDXX.log; fi
    else echo "****** Skipping Short Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
fi

if [[ $RUN_SMART_L == 1 ]]
    then echo "****** Starting Long Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

    smartctl -t long /dev/$SDXX |& tee -a $DIR/$SDXX.log

              smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp     #create file for while to watch for test to be complete
              echo ""; echo "" |& tee -a $DIR/$SDXX.log   #add padding before progress counter

              #wait for temp file to not contain "progress", indicating that test has completed
              while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                do
                  echo -e "\r\033[1A\033[1A\033[0K" |& tee -a $DIR/$SDXX.log
                  smartctl -a /dev/$SDXX | grep "remaining" |& tee -a $DIR/$SDXX.log
                  smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp   #update file for 'while' to watch for test to be complete
                  sleep 5
                done

                rm $DIR/$SDXX.tmp                           #clean up
                echo -e "\r\033[1A\033[1A\033[0K" |& tee -a $DIR/$SDXX.log   #remove progress counter

    echo "******  Status After Long Smart Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
    smartctl -l selftest /dev/$SDXX |& tee -a $DIR/$SDXX.log

    echo "******  Smart Tests Complete ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

          #email
          if [ SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX disktest status after long test" $EMAIL; fi
          if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after long test" $EMAIL < $DIR/$SDXX.log; fi




    else echo "****** Skipping Long Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
fi

if [[ $RUN_BADBLOCKS == 1 ]]
    then echo "****** Starting Badblocks ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

#badblocks goes to different log file until the weirdness can be corrected.

    badblocks -b 4096 -wsv /dev/$SDXX |& tee -a $DIR/$SDXX_blocks.log

    echo "******  Badblocks Complete, running Short Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

      smartctl -t short /dev/$SDXX |& tee -a $DIR/$SDXX.log

                smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp  #create file for while to watch for test to be complete
                echo ""; echo "" #add padding before progress counter

                #wait for output of smartctl to indicate that test has completed
                while grep -c "progress" $DIR/$SDXX.tmp > /dev/null
                  do
                    echo -e "\r\033[1A\033[1A\033[0K"
                    smartctl -a /dev/$SDXX | grep "remaining"
                    smartctl -a /dev/$SDXX > $DIR/$SDXX.tmp
                    sleep 5
                  done

                  rm $DIR/$SDXX.tmp  #clean up
                  echo -e "\r\033[1A\033[1A\033[0K" |& tee -a $DIR/$SDXX.log   #remove progress counter

    echo "******  Status After Badblocks ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

    smartctl -s on -H -i -A -l error -l selftest /dev/$SDXX |& tee -a $DIR/$SDXX.log

          if [ $SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX disktest status after badblocks" $EMAIL; fi
          if [ $SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after badblocks" $EMAIL < $DIR/$SDXX.log; fi

    else echo "****** Skipping Badblocks ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
fi

if [[ $RUN_SPEED_TEST == 1 ]]
    then echo "****** Starting r/w Speed Test ******" |& tee -a $DIR/$SDXX.log
        echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp

#need to add time stamp to these so I can see when they started

    echo "1G file size speed test" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              dd if=/dev/zero of=/dev/$SDXX bs=1G count=4 oflag=dsync |& grep "bytes" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
    echo "64M file size speed test" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              dd if=/dev/zero of=/dev/$SDXX bs=64M count=64 oflag=dsync |& grep "bytes" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
    echo "1M file size speed test" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              dd if=/dev/zero of=/dev/$SDXX bs=1M count=1k oflag=dsync |& grep "bytes" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
    echo "8K file size speed test" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              dd if=/dev/zero of=/dev/$SDXX bs=8k count=4k oflag=dsync |& grep "bytes" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
    echo "512B file size speed test" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
              dd if=/dev/zero of=/dev/$SDXX bs=512 count=1000 oflag=dsync |& grep "bytes" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp

        if [ $SEND_EMAIL == 1 ]; then mail -s "$SDXX disktest status after speed test" $EMAIL < $DIR/$SDXX.tmp; fi
        if [ $SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after speed test" $EMAIL < $DIR/$SDXX.log; fi

    rm $DIR/$SDXX.tmp   #clean up
    else echo "****** Skipping r/w Speed Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
fi


# if [[ $RUN_ZFS_TEST == 1 ]]
#     then echo "****** Starting ZFS Compression Test ******" |& tee -a $DIR/$SDXX.log
#         echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
#
########################## #zfs script goes here
#  outline:
#       create single disk zfs pool w/ compression
#       run standard single pass r/w test
#       destroy zfs pool
#
#
# the below should be able to be reconfigured/written to impliment the zfs test
#
#                 sudo parted /dev/sdxx mklabel gpt
#                 sudo parted -a opt /dev/sdxx mkpart primary 0% 100%
#
#                 zpool create -f -o ashift=12 -O logbias=throughput -O compress=lz4 -O dedup=off -O atime=off -O xattr=sa <unique_pool_name> /dev/sdxx
#                 zpool export <unique_pool_name>
#                 sudo zpool import -d /dev/disk/by-id <unique_pool_name>
#                 sudo chmod -R ugo+rw /<unique_pool_name>
#
#                 fill test
#                 f3write /<unique_pool_name> && f3read /<unique_pool_name>
#                 zpool scrub <unique_pool_name>  #this obviously has to be confirmed that it outputs results (tmp file)
#
#                 #nuke drive:
#
#                 dd if=/dev/zero of=/dev/sdXX bs=512 count=10  #clear first sector
#                 dd if=/dev/zero of=/dev/sdXX bs=512 seek=$(( $(blockdev --getsz /dev/sdXX) - 4096 )) count=1M  #clear last sector?
#
# #
#
#         if [ SEND_EMAIL == 1 ]; then mail -s "$SDXX disktest status after zfs test" $EMAIL < $DIR/$SDXX.tmp; fi
#         if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after zfs test" $EMAIL < $DIR/$SDXX.log; fi
#
#     rm $DIR/$SDXX.tmp   #clean up
#
#     else echo "****** Skipping ZFS Compression Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
# fi



echo "" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log   #add padding
echo  "****** End of Testing ******" |& tee -a $DIR/$SDXX.log

exit 0
