# disktest
script for testing incoming sata/sas drives

## Instructions

must be run as sudo
need to insert descriptions/syntax for flags

-y
-a
-s
-l
-b
-w
-z
-m
-e
-d

### Dependencies
  * smartctl (smartmontools)
  * badblocks (e2fsprogs)     .only applies to badblocks test
  * zfs                       .only applies to zfs test
  * f3                        .only applies to zfs test

### Other Notes
designed for sata/sas disks only, ATA info reporting is not enabled
must be run as root

## Testing Sequence (checks indicate sections with completed programing)
[x] smart test - short
[x] smart test - Long
[x] badblocks - standard 4 pass r/w
[x] test/report drive r/w speed
[ ] zfs r/w test under compression
  [ ] create single disk zfs pool w/ compression
  [ ] run standard single pass r/w test
  [ ] destroy zfs pool
[ ] run short/long smart test again at end?
  [ ] create flag for this?

## Possible Future Development
[ ] insert time stamps in log
[ ] update "**skipping" and "**starting" inserts to make sure they log correctly
[ ] confirm if r/w speed test is destructive
  [ ] optional: add r/w test for when drive is in use?
[ ] add confirmation messages at beginning of script
  [ ] confirm device name and if badblocks/zfs is selected, confirm data erasure
[ ] set up to run program in background
[ ] allow input of a list of multiple drives
[ ] flags for automatic enable/disable of individual tests
  [ ] -b flag for run in background
  [ ] -z flag for zfs
[ ] implement F3 as an additional test to check for fake size reporting drives?
