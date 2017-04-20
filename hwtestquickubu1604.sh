#! /bin/bash

# hwtestquickubu1604.sh
# Test hardware with Ubuntu 16.04 Desktop live GNU/Linux distribution

# Michael McMahon

# To run this script, boot Ubuntu 16.04 Desktop, try, and follow these instructions:
# Open a terminal and run this script with:
# sudo chmod 755 /media/ubuntu/YOURDRIVE/hwtestquick1604.sh
# sudo ./media/ubuntu/YOURDRIVE/hwtestquick1604.sh
# OR
# sudo /bin/bash /media/ubuntu/YOURDRIVE/hwtestquick1604.sh

# Check if the current user is root.
#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Saving log file as date and time.
logfile=/tmp/$(date +%Y%m%d-%H%M).txt
exec &> >(tee -a "$logfile")

echo \ 
echo Adding Universe entries to apt sources list...
# These lines will override your /etc/apt/sources.list file.  Comment out or remove this section and manually add universe, if you absolutely cannot use a live OS.
echo deb http://archive.ubuntu.com/ubuntu/ xenial main restricted universe > /etc/apt/sources.list
echo deb http://security.ubuntu.com/ubuntu/ xenial-security main restricted universe >> /etc/apt/sources.list
echo deb http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted universe >> /etc/apt/sources.list
echo \ 

echo Installing packages for stress test...
apt-get update
apt-get install -y ledmon
apt-get install -y lm-sensors
#apt-get install -y memtester
apt-get install -y smartmontools
apt-get install -y stress
#apt-get install -y stress-ng
echo \ 

echo Checking load and temperatures before stress test...
echo \ 
uptime
echo \ 
sensors
echo \ 
echo Testing CPU with 55 second stress test...
echo If a kernel panic occurs, check CPU and RAM.
stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -v --timeout 10s
echo CPU stress test is complete.
echo \ 
echo Checking load and temperatures after stress test...
echo \ 
uptime
echo \ 
sensors
echo \ 

echo Checking RAM capacity...
free -g
echo \ 
echo Checking RAM speed...
echo \ 
dmidecode -t 17 | grep Speed | grep -v Unknown | tail -n 2
echo \ 
echo Check that the RAM capacity and speed are correct.
echo Your RAM clock speed may be different because of CPU or motherboard designs.
echo \ 

echo Testing RAM with stress...
stress --vm-bytes $(cat /proc/meminfo | grep mF | awk '{printf "%d\n", $2 * 0.9}')k --vm-keep -m 1
echo \ 

#echo Testing RAM with memtester...
# Lock times out on 256GB of memory.  Use memtest+.
#sudo memtester $(free -m | head -n 2 | tail -n 1 | awk '{print $7 * 0.9}') 1
#echo \ 

echo Checking storage drives...
lsblk
smartctl --xall /dev/sda | grep -e Firmware -e Rotation -e Model
echo \ 

echo Testing HDDs with hdparm...
# SSDs should be excluded.
cd /tmp
lsblk -d -o name,rota | grep -v -e 0 -e sr -e loop -e NAME | awk '{ print "sudo hdparm -tT /dev/" $1 }' > hdparm.sh
sh hdparm.sh
echo \ 

echo Network Interface Cards with ip a...
ip a | awk '{ print substr($2, 1, length($2)-1)}' | grep -v -e fore -e : -e se -e / -e lo
echo Network Interface Cards with ifconfig...
ifconfig | awk '{ print $1}' | grep -v -e coll -e RX -e TX -e inet -e UP -e Interr -e lo -e '^$'
echo Mac Addresses:
cat /sys/class/net/*/address | grep -v 0:00:00:0
echo Generating macaddresses.csv...
cat /sys/class/net/*/address | grep -v 0:00:00:0 | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}' > /tmp/macaddresses.csv # Creates a csv of all Mac Addresses (Excluding IPMI)
echo If network ports are missing, ensure the latest firmware is installed and
echo Intel cards are switched on with BootUtil.exe -flashenable -all
echo \ 

echo Testing network cards with ethtool...
ip a | awk '{ print "sleep 1 && sudo ethtool -t " substr($2, 1, length($2)-1) " 2>/dev/null"}' | grep -v -e fore -e : -e se -e /\  -e /2 -e lo > ethtest.sh
sh ethtest.sh
echo \ 

echo Generating blink.sh...
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print "sleep 1 && sudo ledctl locate=" substr($2, 1, length($2)-1)}' > blink.sh
echo sudo umount /media/ubuntu/FAT16 >> blink.sh
echo Test drive LED lights for each drive with:
echo ledctl locate=/dev/sda
echo \ 
echo Or run sh blink.sh to blink all drives with 1 second delay between each drive.
echo If drives fail to light, try again with controller card.
echo If lights do not work, check GPIO cable and backplane pins.
echo \ 

echo After checking the output and LED lights, shutdown with:
echo sudo shutdown -h now
echo Wait a moment and press the enter key.
echo \ 

echo Log saved to $logfile
echo \ 
