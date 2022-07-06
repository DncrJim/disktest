#!/bin/bash

#notes:
#single incoming variable for drive name (sdxx)
#requires: smartctl, badblocks, zfs
#overwrites existing .log file when it starts

# it is suggested to run tool once first with just -d <disk> to confirm that the smart tests complete successfully

#insert other variables (selections may be overwritten by flags below)
ERASE_IT_ALL="n"  #sets erase to no
DIR=""            #location of save files (directory must exist), $HOME will be root home (I think?), "" for / (unconfirmed)
RUN_SMART_S=0     # 1 = run
RUN_SMART_L=0     # 1 = run
RUN_BADBLOCKS=0   # 1 = run
RUN_SPEED_TEST=0  # 1 = run
RUN_ZFS_TEST=0    # 1 = run
UNATTENDED=0      # 0 = run in foreground, 1 = run in unaddended mode (background disowned)(not yet implimented)
SEND_EMAIL=1      # 0 = no emails, 1 = email status updates, 2 = email full log each time
FORMAT=0          # 0 = no format, 1 = gpt, single primary part 0% 100%, could add more numbers later for other formats
EMAIL="root"

#import flags and save to variables
  #flags override settings saved above
while getopts ybaslbwzmf:e:d: option
do
  case "${option}"
    in
    y) ERASE_IT_ALL="y" ;;
    a) RUN_ALL=1;;
    s) RUN_SMART_S=1 ;;
    l) RUN_SMART_L=1 ;;
    b) RUN_BADBLOCKS=1 ;;
    w) RUN_SPEED_TEST=1 ;;
    z) echo "zfs testing is not yet implimented; goodbye." ; exit 1 ;;
    u) echo "unattended mode not yet implimented; goodbye." ; exit 1 ;;
    m) SEND_EMAIL=${OPTARG} ;;
    e) EMAIL=${OPTARG} ;;
    d) DISK=${OPTARG} ;;
    f) FORMAT=1 ;;
    *) echo "you've used an invalid flag; goodbye." ; exit 1 ;;
  esac
done

#check if multiple -d variables provided, insert code to test if running in unattended mode.


#test device name variable
if [ -z "$DISK" ] ; then echo "missing argument" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if there's no variable, throw error
if [[ ${#DISK} > 4 || ${#DISK} < 3 ]] ; then echo "incorrect syntax" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if variable $1 is greater than 4 or less than 3 chars, throw error
if [[ "sd" != "${DISK:0:2}" ]] ; then echo "incorrect syntax" ; echo "usage: disktest.sh -d <sdxx>" ; exit 1 ; fi  #if variable $1 does not begin with first two chars "sd", throw error

#set disk variable - this will need to move/change when implimenting multi-disk launch
SDXX=$DISK

#test to make sure flags have not created conflict
if [[ $RUN_ALL == 1 ]] ; then
    if [[ $RUN_SMART_S == 1 ]] || [[ $RUN_SMART_L == 1 ]] || [[ $RUN_BADBLOCKS == 1 ]] || [[ $RUN_SPEED_TEST == 1 ]] || [[ $RUN_ZFS_TEST == 1 ]] ; then
      echo "the chosen flags conflict; goodbye." ; exit 1
    else
      RUN_SMART_S=1 ; RUN_SMART_L=1 ; RUN_BADBLOCKS=1 ; RUN_SPEED_TEST=1 ; RUN_ZFS_TEST=1
    fi
fi

#insert warning for disk overwrite if a flag is selected which can delete data
if [[ $RUN_BADBLOCKS == 1 ]] || [[ $RUN_SPEED_TEST == 1 ]] || [[ $RUN_ZFS_TEST == 1 ]] || [[ $FORMAT == 1 ]]
 then
    while [[ $ERASE_IT_ALL != "y" ]]
      do
        echo -n "Are you sure you are willing to lose any/all data on /dev/$SDXX? (y/n): "
        read ERASE_IT_ALL
          if [[ $ERASE_IT_ALL == "n" ]] ; then echo "goodbye." ; exit 1
        elif [[ $ERASE_IT_ALL != "y" ]] ; then echo "sorry, I didn't understand your response.."
          fi
      done
  fi

#exit if no tests have been selected
if [[ $RUN_SMART_S == 0 ]] && [[ $RUN_SMART_L == 0 ]] && [[ $RUN_BADBLOCKS == 0 ]] && [[ $RUN_SPEED_TEST == 0 ]] && [[ $RUN_ZFS_TEST == 0 ]] && [[ $FORMAT == 0 ]]
  then echo "no tests selected; goodbye." ; exit 1
 fi

#insert code to run in unaddended mode if UNATTENDED = 1
#related: insert code to launch multiple disks concurrently in unaddended mode

######################################
#######  MAIN BODY OF TESTING

#note: the following line overwrites any existing file
echo "******  Status Before Testing $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee $DIR/$SDXX.log; echo "" |& tee $DIR/$SDXX.log

#activate S.M.A.R.T. just in case it isn't and print initial drive info to log file
smartctl -s on -H -i -A -l error -l selftest /dev/$SDXX |& tee -a $DIR/$SDXX.log

      #email
      if [ $SEND_EMAIL > 0 ]; then mail -s "$SDXX disktest status initial" $EMAIL < $DIR/$SDXX.log; fi

if [[ $RUN_SMART_S == 1 ]]
    then echo "****** Starting Short Test $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

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
    then echo "****** Starting Long Test $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

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
          if [ $SEND_EMAIL == 1 ]; then smartctl -H -l selftest /dev/$SDXX | mail -s "$SDXX disktest status after long test" $EMAIL; fi
          if [ $SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after long test" $EMAIL < $DIR/$SDXX.log; fi



    else echo "****** Skipping Long Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
fi

if [[ $RUN_BADBLOCKS == 1 ]]
    then echo "****** Starting Badblocks $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log

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
    then echo "****** Starting r/w Speed Test $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log
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

# #################################################
#
# if [[ $RUN_ZFS_TEST == 1 ]]
#     then echo "****** Starting ZFS Compression Test $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log
#         echo "" |& tee -a $DIR/$SDXX.log $DIR/$SDXX.tmp
#
# #   create fresh partition on disk
#
#    parted /dev/$SDXX mklabel gpt
#    parted -a opt /dev/$SDXX mkpart primary 0% 100%
#
# #   create unique single disk zfs pool with compression
#
#    POOLNAME="zfs_testing_pool_$SDXX"
#    zpool create -f -o ashift=12 -O logbias=throughput -O compress=lz4 -O dedup=off -O atime=off -O xattr=sa $POOLNAME /dev/$SDXX
#    zpool export $POOLNAME
#    sudo zpool import -d /dev/disk/by-id $POOLNAME
#    sudo chmod -R ugo+rw /$POOLNAME   #unknown usage of slash
#
# #   fill test - single pass r/w test
#
#     f3write /$POOLNAME && f3read /$POOLNAME
#     zpool scrub $POOLNAME  #this obviously has to be confirmed that it outputs results (tmp file)
#
# #   overwrite to purge zfs from disk:
#
#     dd if=/dev/zero of=/dev/$SDXX bs=512 count=10  #clear first sector
#     dd if=/dev/zero of=/dev/$SDXX bs=512 seek=$(( $(blockdev --getsz /dev/sdXX) - 4096 )) count=1M  #clear last sector?
#
#         if [ SEND_EMAIL == 1 ]; then mail -s "$SDXX disktest status after zfs test" $EMAIL < $DIR/$SDXX.tmp; fi
#         if [ SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after zfs test" $EMAIL < $DIR/$SDXX.log; fi
#
#     rm $DIR/$SDXX.tmp   #clean up
#
#     else echo "****** Skipping ZFS Compression Test ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
# fi
#
# #################################################


if [[ $FORMAT == 1 ]]
    then echo "****** Starting Disk Formatting $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log
        echo "" |& tee -a $DIR/$SDXX.log

            parted /dev/$SDXX mklabel gpt; S1=$?
            parted -a opt /dev/$SDXX mkpart primary 0% 100%; S2=$?

            SUCCESS=$(($S1 + $S2))
            if [ $SUCCESS -ne 0 ]; then
                  echo "An error has occured while attempting to format the disk: /dev/$SDXX" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
                  if [ $SEND_EMAIL == 1 ]; then echo "An error has occured while attempting to format the disk: /dev/$SDXX" | mail -s "$SDXX disktest formatting failed" $EMAIL; fi

            else
                  echo "$SDXX has been successfully formatted" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
                  if [ $SEND_EMAIL == 1 ]; then echo "$SDXX has been successfully formatted" | mail -s "$SDXX disktest formatting successful" $EMAIL; fi
            fi

          if [ $SEND_EMAIL == 2 ]; then mail -s "$SDXX disktest status after formatting" $EMAIL < $DIR/$SDXX.log; fi

      else echo "****** Skipping Disk Formatting ******" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log
  fi


echo "" |& tee -a $DIR/$SDXX.log; echo "" |& tee -a $DIR/$SDXX.log   #add padding
echo  "****** End of Testing $(date "+%Y.%m.%d %H:%M:%S") ******" |& tee -a $DIR/$SDXX.log

exit 0
