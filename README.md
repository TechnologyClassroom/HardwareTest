# HardwareTest

Scripts to stress test the hardware of your computer.

Michael McMahon

WARNING: USE AT YOUR OWN RISK.  THESE SCRIPTS INTENTIONALLY PLACE STRAIN ON YOUR
SYSTEM.  IF YOU CANNOT ACCEPT HARDWARE FAILURE, DO NOT USE THESE SCRIPTS.  USE
THESE SCRIPTS ON NEW SYSTEMS ONLY.  I AM NOT RESPONSIBLE FOR BROKEN HARDWARE OR
LOSS OF DATA.  READ AND UNDERSTAND THE SCRIPT BEFORE RUNNING ON ANY HARDWARE.

These scripts are not meant to be run from your operating system.  Boot up a
live GNU/Linux distribution first and then run the script.

Download links for compatible live GNU/Linux Distributions:

- [GRML](https://grml.org/download/)
- [Slax](https://www.slax.org/)
- [Ubuntu 14.04 Desktop](http://releases.ubuntu.com/14.04/)
- [Ubuntu 16.04 Desktop](http://releases.ubuntu.com/16.04/)

If there is a problem with your hardware, this script should cause your computer
to crash.  Finding the part of the script that crashes can help troubleshoot the
problem area.

Bash scripts can do nearly anything to your system.  In general, always read
over scripts before using them.  If you want to remove functionality or a test,
remove a line or add a pound sign (#) at the beginning of unwanted lines.

The ```*proprietary.sh``` scripts download and install proprietary software that
may not have your best interest in mind.  ```hwtest.sh``` should be used to
avoid this problem.

Contributions:

- I have made scripts for some specific live operating systems.  Please,
  contribute changes for more operating systems.
- I am looking for more tests.
- Eventually, I would like to build my own live GNU/Linux distro that runs this
  script automatically built upon MLL, Arch, or GRML.
