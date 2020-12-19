# disktest
script for testing incoming sata/sas drives

## Instructions

must be run as sudo
need to insert descriptions/syntax for flags

`-y`  Will not promt before erasing data\
\
`-a`  Runs all, `-slbw` (`z` will be included when available)\
`-s`  Runs a short test with `smartctl -t short`\
`-l`  Runs a long test with `smartctl -t long`\
`-b`  Runs `badblocks`\
`-w`  Runs a write speed test\
`-z`  `.zfs` test (feature unavailble at this time)\
\
`-m`  Sends email 0 = no emails, 1 (default) = email status updates, 2 = email full log each time\
`-e`  Sets email address, default `root`\
`-d`  Sets disk `sdxx`

### Dependencies
  * `smartctl` (smartmontools)
  * `badblocks` (e2fsprogs)     .only applies to badblocks test
  * `zfs`                       .only applies to zfs test
  * `f3`                        .only applies to zfs test

### Other Notes
designed for sata/sas disks only, ATA info reporting is not enabled
must be run as root

## Testing Sequence (checks indicate sections with completed programing)
- [x] smart test - short
- [x] smart test - Long
- [x] badblocks - standard 4 pass r/w
- [x] test/report drive r/w speed
- [ ] zfs r/w test under compression
  - [ ] create single disk zfs pool w/ compression
  - [ ] run standard single pass r/w test
  - [ ] destroy zfs pool
- [ ] run short/long smart test again at end?
  - [ ] create flag for this?

## Possible Future Development
- [ ] insert time stamps in log
- [ ] update "**skipping" and "**starting" inserts to make sure they log correctly
- [ ] confirm if r/w speed test is destructive
  - [ ] optional: add r/w test for when drive is in use?
- [ ] add confirmation messages at beginning of script
  - [ ] confirm device name and if badblocks/zfs is selected, confirm data erasure
- [ ] set up to run program in background
- [ ] allow input of a list of multiple drives
- [ ] flags for automatic enable/disable of individual tests
  - [ ] -b flag for run in background
  - [ ] -z flag for zfs
-[ ] implement F3 as an additional test to check for fake size reporting drives?
