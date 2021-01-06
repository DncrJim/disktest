# disktest
script for testing incoming sata/sas drives

## Instructions

must be run as root

`-y`  Will not prompt before erasing data\
\
`-a`  all tests, `-slbw` (`z` will be added when complete)\
`-s`  short S.M.A.R.T test `smartctl -t short`\
`-l`  long S.M.A.R.T test `smartctl -t long`\
`-b`  `badblocks` 4 passes of write/read\
`-w`  write speed test\
`-z`  `.zfs` test (not yet implemented)\
\
`-u`  unattended mode (not yet implemented)\
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

## Testing Sequence (checks indicate sections with completed programing)
- [x] smart test - Short
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
- [ ] check for dependencies (based on selected flags) before running
- [ ] update "**skipping" and "**starting" inserts to make sure they log correctly
- [x] confirm if r/w speed test is destructive
  - [ ] optional: add r/w test for when drive is in use?
- [ ] add confirmation messages at beginning of script
  - [ ] confirm device name and
  - [x] if badblocks/zfs is selected, confirm data erasure
- [ ] set up to run program in background
- [ ] allow input of a list of multiple drives
- [ ] flags for automatic enable/disable of individual tests
  - [ ] -u flag for run in unattended mode (background/disown)
  - [ ] -z flag for zfs
- [ ] implement F3 as an additional test to check for fake size reporting drives?
