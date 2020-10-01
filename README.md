# disktest
script for testing incoming sata/sas drives

##Testing Sequence (checks indicate completed sections)
[*] smart test - short
[*] smart test - Long
[*] badblocks - standard 4 pass r/w
[ ] test/report drive r/w speed
[ ] zfs r/w test under compression
  [ ] create single disk zfs pool w/ compression
  [ ] run standard single pass r/w test
  [ ] destroy zfs pool

## Dependencies
* badblocks (e2fsprogs)
* smartctl (smartmontools)
* zfs

## Possible Future Development
[ ] insert time stamps in log
[ ] update "**skipping" and "**starting" inserts to make sure they log correctly
[ ] confirm r/w test is destructive
  [ ] add optional r/w test for when drive is in use
[ ] add confirmation messages at beginning of script
  [ ] confirm device name and if badblocks/zfs is selected, confirm data erasure
[ ] set up to run program in background
[ ] allow input of a list of multiple drives
[ ] flags for automatic enable/disable of individual tests
  [ ] -y flag to automatically agree to all tests
  [ ] -a for all tests (-slbz)
  [ ] -z flag for zfs

## Other Notes:
designed for sata/sas disks only, ATA info reporting is not enabled
must be run as root
