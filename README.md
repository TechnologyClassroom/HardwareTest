# HardwareTest

Scripts to stress test the hardware of your computer.

Michael McMahon

WARNING: USE AT YOUR OWN RISK. THESE SCRIPTS INTENTIONALLY PLACE STRAIN ON YOUR
SYSTEM. IF YOU CANNOT ACCEPT HARDWARE FAILURE, DO NOT USE THESE SCRIPTS. USE
THESE SCRIPTS ON NEW SYSTEMS ONLY. I AM NOT RESPONSIBLE FOR BROKEN HARDWARE OR
LOSS OF DATA. READ AND UNDERSTAND THE SCRIPT BEFORE RUNNING ON ANY HARDWARE.

These scripts are not meant to be run from your operating system. Boot up a
live GNU/Linux distribution first and then run the script.

Download links for compatible live GNU/Linux Distributions:

- [Trisquel Desktop](https://trisquel.info/en/download) (Recommended for hwtest.sh)
- [Ubuntu Desktop](https://ubuntu.com/download/desktop) (Recommended for hwtestlanproprietary.sh)
- [Debian](https://www.debian.org/CD/live/)
- These scripts should work with most Debian-based distributions.

If there is a problem with your hardware, this script should cause your computer
to crash. Finding the part of the script that crashes can help troubleshoot the
problem area.

Bash scripts can do nearly anything to your system. In general, always read
over scripts before using them. If you want to remove functionality or a test,
remove a line or add a pound sign (#) at the beginning of unwanted lines.

- hwtest.sh is a variation of hwtestproprietary.sh with all nonfree 
software removed. I still use this software and this is the version that
 I use these days.
- hwtestproprietary.sh is a variation of hwtest.sh with some 
additional nonfree software that can interact with some hardware that 
requires vendor tools.
- hwtestlanproprietary.sh is a variation of hwtestproprietary.sh with 
external download locations replaced with local network locations. This 
speeds things up at scale and reduces load on external resources.

The ```*proprietary.sh``` scripts download and install proprietary software that
may not have your best interest in mind. ```hwtest.sh``` should be used to
avoid this problem.

Contributions:

- I have made scripts for some specific live operating systems. Please,
  contribute changes for more operating systems.
- I am looking for more tests.
- Eventually, I would like to build my own live GNU/Linux distro that runs this
  script automatically built upon a minimal operating system.
