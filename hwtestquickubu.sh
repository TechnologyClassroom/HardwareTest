#! /bin/bash

# hwtestquickubu.sh
# Test hardware with Ubuntu 14.04 Desktop live GNU/Linux distribution

# Michael McMahon

# To run this script, boot Ubuntu Desktop 16.04 or 14.04, try, and follow these instructions:
# Open a terminal and run this script with:
# sudo bash bluearchive.sh
# OR
# sudo /bin/bash bluearchive.sh
# OR
# sudo chmod 755 bluearchive.sh
# sudo ./bluearchive.sh



# Initialization checks

# Check if the current user is root.
#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check for /bin/bash.
if [ "$BASH_VERSION" = '' ]; then
	echo You are not using bash.
	echo Use this syntax instead:
	echo sudo bash bluearchive.sh
	exit 1
fi

# Check networking
# https://unix.stackexchange.com/questions/190513/shell-scripting-proper-way-to-check-for-internet-connectivity
echo Checking network...
if ping -q -c 1 -W 1 google.com >/dev/null; then
	echo "The network is up."
else
	echo "The network is down."
	echo Check connection and restart script!
	exit 1
fi

# Log all stdout to logfile with date.
logfile=/tmp/$(date +%Y%m%d-%H%M).txt
exec &> >(tee -a "$logfile")
echo Saving log file as $logfile.
echo \ 



# Updates and dependencies

echo Adding Universe entries to apt sources list...
# These lines will override your /etc/apt/sources.list file.  Comment out or remove this section and manually add universe, if you absolutely cannot use a live OS.
if [ $(cat /etc/*-release | grep 16.04 | wc -l) -gt 4 ]
then
	echo Ubuntu 16.04 detected...
	echo deb http://archive.ubuntu.com/ubuntu/ xenial main restricted universe > /etc/apt/sources.list
	echo deb http://security.ubuntu.com/ubuntu/ xenial-security main restricted universe >> /etc/apt/sources.list
	echo deb http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted universe >> /etc/apt/sources.list
	echo \ 
fi

if [ $(cat /etc/*-release | grep 14.04 | wc -l) -gt 4 ]
then
	echo Ubuntu 14.04 detected...
	echo deb http://archive.ubuntu.com/ubuntu/ trusty main restricted universe > /etc/apt/sources.list
	echo deb http://security.ubuntu.com/ubuntu/ trusty-security main restricted universe >> /etc/apt/sources.list
	echo deb http://archive.ubuntu.com/ubuntu/ trusty-updates main restricted universe >> /etc/apt/sources.list
	echo \ 
fi

echo Installing packages for stress test...
apt-get update 2> /dev/null >> /dev/null # live 1604 has errors.  Programs still install.
#apt-get install -y fio >> /dev/null
apt-get install -y ledmon >> /dev/null
apt-get install -y lm-sensors >> /dev/null
#apt-get install -y memtester >> /dev/null
apt-get install -y smartmontools >> /dev/null
apt-get install -y stress >> /dev/null
#apt-get install -y stress-ng >> /dev/null
mkdir /tmp/storage
echo \ 



# CPU

echo Checking load and temperatures before stress test...
echo \ 
uptime
echo \ 
sensors
echo \ 

echo If a kernel panic occurs, check CPU and RAM.
#echo Testing CPU with 4 hour stress test...
#stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -t 4h
echo Testing CPU with 55 second stress test...
stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -t 55
echo CPU stress test is complete.
echo \ 

echo Checking load and temperatures after stress test...
echo \ 
uptime
echo \ 
sensors
echo \ 



# RAM

echo Checking RAM capacity in GB...
free -g
echo Check that the RAM capacity is correct.
echo Smaller values are acceptable.
echo If the difference is more than one stick, check RAM seating.
echo \ 
echo Checking RAM speed...
echo \ 
dmidecode -t 17 | grep Speed | grep -v Unknown | tail -n 2
echo \ 
echo Check that the RAM speed is correct.
echo Your RAM clock speed may be different because of CPU or motherboard designs.
echo \ 

echo Testing RAM with 55 second stress test...
stress --vm-bytes $(cat /proc/meminfo | grep mF | awk '{printf "%d\n", $2 * 0.9}')k --vm-keep -m 1 -t 55
echo Small test complete.  Use memtest+.
echo \ 

#echo Testing RAM with memtester...
# Lock times out on 256GB of memory.  Use memtest+.
#sudo memtester $(free -m | head -n 2 | tail -n 1 | awk '{print $7 * 0.9}') 1
#echo \ 



# Storage

echo Checking storage drives...
lsblk
echo Generating smartmon.sh...
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print "smartctl --xall " substr($2, 1, length($2)-1) " | grep -e Firmware -e Rotation -e Model"}' > smartmon.sh
echo Executing smartmon.sh...
sh smartmon.sh
echo \ 

# hdparm
echo Generating hdparm.sh...
cd /tmp
if [ $(cat /etc/*-release | grep 16.04 | wc -l) -gt 4 ]
then
	# SSDs and flash drives are excluded.
	lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e usb -e ‘sda ‘ -e ‘sdb ‘ -e loop -e NAME | awk '{ print "sudo hdparm -tT /dev/" $1 " > /tmp/storage/" $1 " &" }' > hdparm.sh
	echo hdparm tests will start in parallel.  Do not start any other drive tests until complete.
	echo Logs can be found in the /tmp/storage/ folder.
fi
if [ $(cat /etc/*-release | grep 14.04 | wc -l) -gt 4 ]
then
	# SSDs are excluded.  Older version of lsblk does not have tran.
	lsblk -d -o name,rota | grep -v -e 0 -e sr -e loop -e NAME | awk '{ print "sudo hdparm -tT /dev/" $1 " > /tmp/storage/" $1 " &" }' > hdparm.sh
fi
echo Testing HDDs with hdparm...
sh hdparm.sh
echo \ 



# Networking

# Report network cards and Mac Addresses
if [ $(ls /sbin/ip | wc -l) -gt 0 ]
then
	echo Network Interface Cards with ip a...
	ip a | awk '{ print substr($2, 1, length($2)-1)}' | grep -v -e fore -e : -e se -e / -e lo
else
	echo Network Interface Cards with ifconfig...
	ifconfig 2> /dev/null | awk '{ print $1}' | grep -v -e coll -e RX -e TX -e inet -e UP -e Interr -e lo -e '^$'
	# This grep command causes extra memory output.
fi
echo Mac Addresses:
cat /sys/class/net/*/address | grep -v 0:00:00:0
cat /sys/class/net/*/address | grep -v 0:00:00:0 | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}' > /tmp/macaddresses.csv # Creates a csv of all Mac Addresses (Excluding IPMI)
echo If network ports are missing, ensure the latest firmware is installed and
echo Intel cards are switched on with BootUtil.exe -flashenable -all
echo \ 

echo Testing network cards with ethtool...
cd /tmp
ip a | awk '{ print "sleep 1 && sudo ethtool -t " substr($2, 1, length($2)-1) " 2> /dev/null | grep -v -e extra -e result -e Link"}' | grep -v -e fore -e : -e se -e /\  -e /2 -e lo > ethtest.sh
sh ethtest.sh
echo Key: 0 means PASS.
echo Network connection may be broken after ethtool tests.  Reboot to fix connection.
# When we send logs to a central server in the future, we will need to fix or skip this.
echo \ 



# LEDs

echo Generating blink.sh...
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print "sleep 1 && sudo ledctl locate=" substr($2, 1, length($2)-1)}' > blink.sh
echo Test drive LED lights for each drive with:
echo ledctl locate=/dev/sda
echo \ 
echo Run sh /tmp/blink.sh to blink all drives with 1 second delay between each drive.
echo If drives fail to light, try again with controller card.
echo If lights do not work, check backplane, pins, ports, and cables.
echo \ 



# Log details

echo All temporary scripts and logs can be found in the /tmp/ folder.
if [ -z "$serial" ]
then
	echo Log saved to $logfile
else
	echo "Log file $logfile renamed to $serial."
	cp $logfile /tmp/$serial.log
	logfile=/tmp/$serial.log
fi
echo \ 


echo After checking LED lights, shutdown with:
echo sudo shutdown -h now
echo Wait a moment and press the enter key.
echo \ 
