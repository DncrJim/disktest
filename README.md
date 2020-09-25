# disktest
script for testing incoming sata/sas drives

##Testing Sequence (checks indicate completed sections)
[*] smart test - short
[*] smart test - Long
[*] badblocks - standard 4 pass r/w
[ ] zfs r/w test under compression
  [ ] create single disk zfs pool w/ compression
  [ ] run standard single pass r/w test
  [ ] destroy zfs pool

## Dependencies
* badblocks (e2fsprogs)
* smartctl (smartmontools)
* zfs

## Possible Future Development
[ ] add confirmation messages at beginning of script
  [ ] confirm device name and if badblocks/zfs is selected, confirm data erasure
[ ] set up to run program in background
[ ] allow input of a list of multiple drives
[ ] flags for automatic enable/disable of individual tests
[ ] -y flag to automatically agree to all tests
[ ] -a for all tests (-slbz)
[ ] -s flag for short smart
[ ] -l flag for long smart
[ ] -b flag for badblocks
[ ] -z flag for zfs
[ ] -m flag for email updates
[ ] -e to set email

## Other Notes:
designed for sata/sas disks only, ATA info reporting is not enabled
must be run as root
