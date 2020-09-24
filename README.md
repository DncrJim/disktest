# drivetest
script for testing incoming sata/sas drives

not designed for ATA (does not log/export necessary information about drive)
intended to be run as sudo

NOT YET COMPLETED TO USABLE STATE

runs the following tests in order
short smart test
long smart test
badblocks
creates zfs pool on disk w/ compression
  runs standard single pass of write and read tests
destroys zfs pool


prerequisites
badblocks
smartmontools
zfs
other?

Possible additions:
pull variable for list of drives and spawn separate processes?
verbosity trigger for sending emails?
trigger for sending errors?
