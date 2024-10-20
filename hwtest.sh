#!/bin/bash

# hwtest.sh
# version 0.9.18
# Test hardware with Debian based GNU/Linux distributions.
# Michael McMahon

# This script is licensed under the GNU Affero General Public License v3.0
# (AGPL-3.0).  See the LICENSE file for more information.

# Tested on LiveOS Versions of Ubuntu 14.04 Desktop, Ubuntu 16.04 Desktop, GRML
# 2017.05, and Slax 9.6.5.

# To run this script, boot a Debian based distribution and follow these steps:
# Open a terminal and run this script with:
# sudo bash hwtest.sh
# OR
# sudo /bin/bash hwtest.sh
# OR
# sudo chmod 755 hwtest.sh
# sudo ./hwtest.sh

# To skip the three stress tests, use the ```--skipstress``` argument.
# sudo bash hwtest.sh --skipstress



# Initialization checks

# Check for /bin/bash.
if [ "$BASH_VERSION" = '' ]; then
  echo "You are not using bash."
  echo "Use this syntax instead:"
  echo "sudo bash hwtest.sh"
  exit 1
fi

# Check for root.
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# Check networking
# https://unix.stackexchange.com/questions/190513/shell-scripting-proper-way-to-
#   check-for-internet-connectivity
echo Checking network...
if ping -q -c 1 -W 1 google.com >/dev/null; then
  echo "The network is up."
else
  echo "The network is down."
  echo "Check connection and restart script!"
  exit 1
fi

# Disable screensaver
echo "Disabling screensaver..."
xset s off >/dev/null 2>&1
xset -dpms >/dev/null 2>&1
xset s noblank >/dev/null 2>&1
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false \
>/dev/null 2>&1
setterm -blank 0 -powerdown 0  -powersave off >/dev/null 2>&1

# Log all stdout to logfile with date.
logfile=/tmp/$(date +%Y%m%d-%H%M).log
exec &> >(tee -a "$logfile")
echo "Starting logfile as $logfile..."
echo



# Updates and dependencies

echo "Adding Universe entries to apt sources list..."
add-apt-repository universe >/dev/null 2>&1

echo "Installing packages for stress test..."

#apt-get purge -y libappstream3 >/dev/null 2>&1  # This was necessary
                                                 # with Ubuntu 16.04.3
apt-get update >/dev/null 2>&1
for package in dialog ethtool fio ledmon lm-sensors nvme-cli sg3-utils \
               smartmontools sshpass stress sysstat tmux unzip; do
  echo "Installing $package..."
  apt install -y $package >/dev/null 2>&1
done
# Build temporary directory for storage test logs.
mkdir /tmp/storage



# Motherboard

echo "dmidecode strings..."
dmidecode --string bios-version | sed 's/^/bios-version,/'
dmidecode --string bios-release-date | sed 's/^/bios-release-date,/'
dmidecode --string system-manufacturer | sed 's/^/system-manufacturer,/'
dmidecode --string system-product-name | sed 's/^/system-product-name,/'
#dmidecode --string system-version | sed 's/^/system-version,/'
dmidecode --string system-serial-number | sed 's/^/system-serial-number,/'
dmidecode --string system-uuid | sed 's/^/system-uuid,/'
dmidecode --string baseboard-manufacturer | sed 's/^/baseboard-manufacturer,/'
dmidecode --string baseboard-product-name | sed 's/^/baseboard-product-name,/'
dmidecode --string baseboard-version | sed 's/^/baseboard-version,/'
dmidecode --string baseboard-serial-number | sed 's/^/baseboard-serial-number,/'
dmidecode --string baseboard-serial-number | sed 's/^/baseboard-serial-number,/' > /tmp/brief.csv
#dmidecode --string baseboard-asset-tag | sed 's/^/baseboard-asset-tag,/'
dmidecode --string chassis-manufacturer | sed 's/^/chassis-manufacturer,/'
dmidecode --string chassis-type | sed 's/^/chassis-type,/'
#dmidecode --string chassis-version | sed 's/^/chassis-version,/'
dmidecode --string chassis-serial-number | sed 's/^/chassis-serial-number,/'
#dmidecode --string chassis-asset-tag | sed 's/^/chassis-asset-tag,/'



# CPU

echo "Checking CPU model..."
dmidecode --string processor-family | sed 's/^/processor-family,/'
dmidecode --string processor-manufacturer | sed 's/^/processor-manufacturer,/'
dmidecode --string processor-version | sed 's/  / /g' | sed 's/^/processor-version,/'
dmidecode --string processor-frequency | sed 's/^/processor-frequency,/'
grep name /proc/cpuinfo
echo

if [[ $1 != "--skipstress" ]] && [[ $2 != "--skipstress" ]]
then
  echo "Checking load and temperatures before stress test..."
  echo
  uptime
  echo
  sensors
  echo
  
  echo "If a kernel panic occurs, check CPU and RAM."
  echo "Testing CPU with 10 minute stress test..."
  stress --cpu $(grep -e processor /proc/cpuinfo | wc -l) -t $((60*10))
  echo "CPU stress test is complete."
  echo
  
  echo "Checking load and temperatures after stress test..."
  echo
  uptime
  echo
  sensors
  echo
else
  echo "Skipping CPU stress test..."
fi

# Check for --test-all argument
if [ "$1" == "--test-all" ]; then
    echo "Running all tests..."
    # Add the commands that run all tests below:
    ./hwtest.sh        # or call specific test functions if needed
    ./hwtestlanproprietary.sh
    ./hwtestproprietary.sh
    exit 0
fi

# Existing script content...


# RAM

echo "Checking RAM capacity in GB..."
free -g
echo "Check that the RAM capacity is correct."
echo "Smaller values are acceptable."
echo "If the difference is more than one stick, check RAM seating."
echo
echo "Checking RAM speed..."
echo
dmidecode -t 17 | grep Speed | grep -v Unknown | tail -n 2
echo
echo "Check that the RAM speed is correct."
echo "Your RAM clock speed may be different because of CPU or motherboard desig\
ns."
echo

if [[ $1 != "--skipstress" ]] && [[ $2 != "--skipstress" ]]
then
  echo "Testing RAM with 2 minute stress test..."
  # stress --vm-bytes 1k --vm-keep -m 1 -t 120
  stress --vm-bytes $(grep mF /proc/meminfo | awk '{printf "%d\n", $2 * \
  0.9}')k --vm-keep -m 1 -t $((60*2))
  echo "2 minute stress test complete.  Use memtest+."
  echo
  
  # echo "Testing RAM with memtester..."
  # Lock times out on 256GB of memory.  Use memtest+.
  # memtester $(free -m | head -n 2 | tail -n 1 | awk '{print $7 * 0.9}') 1
  # echo
else
  echo "Skipping RAM stress test..."
fi



# Storage

echo "Checking storage drives..."
lsblk

echo "Checking sector sizes..."
fdisk -l | grep dev | grep -v Disk

echo "Generating smartmon.sh..."
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print \
"smartctl --xall " substr($2, 1, length($2)-1) " | grep -e Firmware -e \
Rotation -e Model -e Serial -e result"}' > smartmon.sh
echo "Executing smartmon.sh..."
sh smartmon.sh
sh smartmon.sh | grep Serial | awk '{ print $3 }' | sed 's/^/diskSNs,/' >> /tmp/brief.csv
echo

echo "Checking for Intel SSD drives..."
sed 's/-e Firmware -e Rotation -e Model -e Serial -e result/-i intel 2>\/dev\/null >> intel.txt/g' \
smartmon.sh > intelcheck.sh
bash intelcheck.sh
touch intel.txt
if [ $(wc -l intel.txt) -gt 0 ]
then
  echo "Intel drives were found!"
fi
echo "If Intel drives were expected, check that the controller"
echo "card is set to JBOD."

# echo "Checking nvme drives..."
nvme list
echo "Generating nvme.sh..."
cd /tmp
fdisk -l | grep 'Disk\ .*nvme' | awk '{print "nvme smart-log " substr($2, 1, \
length($2)-1)}' > nvme.sh
echo "Executing nvme.sh..."
sh nvme.sh
echo

# WIP: Create temporary file with all unpartitioned drives that are not flash or
#   SSD drives.
# grep -v -e ram -e sr -e dm -e blocks -e '^$' /proc/partitions | awk '{ \
#sub(/[0-9]/,"",$4); print $4}'
# This command lists all drive and removes numbers.
# Remove entries with duplicates.
# Remainder should be unpartitioned drives.
# Create second list with SSD & Flash drives
# Remove matches found on both lists.
# Remainder should be unpartitioned drives safe for fio or dd tests.

if [ $(lspci | grep 2308 | wc -l) -gt 0 ]
then
  echo "SAS2308 found!"
fi

if [ $(lspci | grep 3008 | wc -l) -gt 0 ]
then
  echo "HBA 3008 found!"
fi

if [ $(lspci | grep 3108 | wc -l) -gt 0 ]
then
  echo "SAS3108 found!"
fi

if [ $(lspci | grep 3224 | wc -l) -gt 0 ]
then
  echo "HBA 3224 found!"
fi

if [ $(lspci | grep Adaptec | wc -l) -gt 0 ]
then
  echo "Adaptec card found!"
fi

if [ $(lspci | grep Atto | wc -l) -gt 0 ]
then
  echo "Atto card found!"
fi

# hdparm
echo "Generating hdparm.sh..."
cd /tmp
if [ $(lsblk -V | grep 2.29.2 | wc -l) -gt 0 ]
then
  # SSDs and flash drives are excluded.
  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e usb -e 'sda ' -e 'sdb '\
-e loop -e NAME | awk '{ print "hdparm -tT /dev/" $1 " > /tmp/storage/"\
$1 " &" }' > hdparm.sh
  echo "hdparm tests will start in parallel.  Do not start any other drive test\
s until complete."
else
  if [ $(grep 16.04 /etc/*-release | wc -l) -gt 4 ]
  then
    # SSDs and flash drives are excluded.
    lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e usb -e 'sda ' -e \
'sdb ' -e loop -e NAME | awk '{ print "hdparm -tT /dev/" $1 " \
> /tmp/storage/" $1 " &" }' > hdparm.sh
    echo "hdparm tests will start in parallel."
    echo "Do not start any other drive tests until complete."
  fi
  if [ $(grep 14.04 /etc/*-release | wc -l) -gt 4 ]
  then
    # SSDs are excluded.  Older version of lsblk does not have tran.
    lsblk -d -o name,rota | grep -v -e 0 -e sr -e loop -e NAME | awk '{ print \
"hdparm -tT /dev/" $1 " > /tmp/storage/" $1 " &" }' > hdparm.sh
  fi
fi
echo "Testing HDDs with hdparm..."
sh hdparm.sh
echo

# dd
# echo "WARNING: If the OS comes up as anything else other than sda and sdb,"
# echo "this will be destructive."
# echo "WARNING: This can be destructive.  Use at your own risk."
#if [ $(grep 16.04 /etc/*-release | wc -l) -gt 4 ]
#then
#  echo "Testing HDDs with dd..."
#  # SSDs and flash drives are excluded.
#  cd /tmp
#  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e 'sda ' -e 'sdb ' -e \
#usb -e loop -e NAME | awk '{ print "dd bs=4M count=2048 if=/dev/zero \
#of=/dev/" $1 " conv=fdatasync status=progress > /tmp/storage/dd" $1 " &" \
#}' > ddtest.sh
#  sh ddtest.sh
#  echo "Use 'iostat' to see activity on drives."
#  echo "Use 'ps aux | grep fio' to see if fio is still running."
#fi
#

# fio
echo "Generating fio4hourtest.sh..."
echo "WARNING: If the OS is NOT on sda and sdb, this will be destructive."
echo "WARNING: This can be destructive.  Use at your own risk."
if [ $(grep 16.04 /etc/*-release | wc -l) -gt 4 ]
then

  # SSDs and flash drives are excluded.
  cd /tmp
  echo "echo 'Stopping hdparm...'" > fio4hourtest.sh
  echo "pkill hdparm" >> fio4hourtest.sh
  echo "echo 'Testing HDDs with fio...'" >> fio4hourtest.sh
  echo "echo 'WARNING: If the OS is NOT on sda and sdb, this will be \
destructive.'" >> fio4hourtest.sh
  echo "echo 'WARNING: This can be destructive.  Use at your own risk.'" \
    >> fio4hourtest.sh
  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e 'sda ' -e 'sdb ' -e \
usb -e loop -e NAME | awk '{ print "fio --name=readwrite --ioengine=libaio \
--iodepth=1 --rw=readwrite --bs=4k --direct=1 --size=512M --numjobs=8 \
--filename=/dev/" $1 " --time_based=7200 --runtime=7200 --group_reporting \
| grep io > /tmp/storage/fio" $1 " &"}' >> fio4hourtest.sh
  # sh fio4hourtest.sh # This can be run from longstress.sh or by
  #   uncommenting tmux line below.
fi
# With help of @tfindelkind from http://tfindelkind.com/2015/08/10/fio-flexible\
#   -io-tester-part5-direct-io-or-buffered-page-cache-or-raw-performance/
# https://wiki.mikejung.biz/Benchmarking#Install_Fio_on_Ubuntu_14.10
# https://tobert.github.io/post/2014-04-28-getting-started-with-fio.html
# https://tobert.github.io/post/2014-04-17-fio-output-explained.html

echo "Storage test logs can be found in the /tmp/storage/ folder."
echo



# tmux and Long stress test
cd /tmp
echo stress --cpu $(grep -e processor /proc/cpuinfo | wc -l) -t 4h \
> cpu.sh
echo "pkill top" >> cpu.sh
echo "pkill iostat" >> cpu.sh
echo "pkill tmux" >> cpu.sh
echo "exit" >> cpu.sh
echo stress --vm-bytes $(grep mF /proc/meminfo | awk '{printf "%d\n", $2 \
* 0.9}')k --vm-keep -m 1 -t 4h > ram.sh
echo "exit" >> ram.sh
echo "iostat -ctd 2" >> fio4hourtest.sh
echo "exit" >> fio4hourtest.sh
# tmux new-session -d -s hwtest \; send-keys 'sh /tmp/cpu.sh && exit' 'C-m' \; \
#   rename-window 'hwtest' \; select-window -t hwtest:0 \; split-window -h \; \
#   send-keys 'sh /tmp/ram.sh && exit' 'C-m' \; split-window -v -t 0 \; \
#   send-keys 'top && exit' 'C-m' \; split-window -v -t 1 \; send-keys 'sh \
#   /tmp/fio4hourtest.sh && exit' 'C-m' \; attach-session -t hwtest
echo "Generating longtest.sh..."
echo "tmux new-session -d -s hwtest \; send-keys 'sh /tmp/cpu.sh && exit' \
'C-m' \; rename-window 'hwtest' \; select-window -t hwtest:0 \; split-window \
-h \; send-keys 'sh /tmp/ram.sh && exit' 'C-m' \; split-window -v -t 0 \; \
send-keys 'top && exit' 'C-m' \; split-window -v -t 1 \; send-keys 'sh \
/tmp/fio4hourtest.sh && exit' 'C-m' \; attach-session -t hwtest" \
> longstress.sh
echo "To run a longer 4 hour stress test on the CPU, RAM, and drives"
echo "simutaneously, run this command as root:"
echo "  sh /tmp/longstress.sh"



# Networking

# Mellanox
if [ $(lspci | grep Mellanox | wc -l) -gt 0 ]
then
  echo "Mellanox card found!"
fi

# Aquantia
if [ $(lspci | grep 1d6a | wc -l) -gt 0 ]
then
  echo "Aquantia card found!"
fi

# Report network cards and Mac Addresses
if [ $(ls /sbin/ip | wc -l) -gt 0 ]
then
  echo "Network Interface Cards with ip a..."
  ip a | awk '{ print substr($2, 1, length($2)-1)}' | grep -v -e fore -e : -e \
se -e / -e lo
else
  echo "Network Interface Cards with ifconfig..."
  ifconfig 2> /dev/null | awk '{ print $1}' | grep -v -e coll -e RX -e TX -e \
inet -e UP -e Interr -e lo -e '^$'
  echo "This grep command causes extra memory output. ¯\_(ツ)_/¯"
fi

echo Mac Addresses:
grep -v 0:00:00:0 /sys/class/net/*/address
grep -v 0:00:00:0 /sys/class/net/*/address | sed -n -e \
'H;${x;s/\n/,/g;s/^,//;p;}' | sed 's/^/NICmac,/' > /tmp/macaddresses.csv
# Create a csv file of all Mac Addresses (Excluding IPMI)
echo "If network ports are missing, ensure the latest firmware is installed and"
echo "Intel cards are switched on with BootUtil.exe -flashenable -all"
echo

echo "Generating ethtest.sh..."
cd /tmp
echo "echo 'Testing network cards with ethtool...'" > ethtest.sh
ip a | awk '{ print "sleep 1 && ethtool -t " substr($2, 1, length($2)-1) \
" 2> /dev/null | grep -v -e extra -e result -e Link"}' | grep -v -e fore -e : \
-e se -e /\  -e /2 -e lo >> ethtest.sh
echo "Key: 0 means PASS." >> ethtest.sh
echo "Network connection may be broken after ethtool tests." >> ethtest.sh
echo "Reboot to fix connection." >> ethtest.sh
echo "To test the network cards, run this command as root:"
echo "  sh /tmp/ethtest.sh"
echo "This may break your network connection until you reboot."
# If sending logs to a central server, skip ethtest.sh
echo



# PCI Devices

if [ $(lspci | grep Altera | grep 0007 | wc -l) -gt 0 ]
then
  echo "BlueFish Neutron Card found!"
fi

echo "Listing all PCI devices..."
lspci
echo



# LEDs

echo "Generating blink.sh..."
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print \
"sleep 1 && ledctl locate=" substr($2, 1, length($2)-1)}' > blink.sh
echo "Test drive LED lights for each drive with:"
echo "ledctl locate=/dev/sda"
echo
echo "Run sh /tmp/blink.sh to blink all drives with 1 second delay between \
drives."
echo "If drives fail to light, try again with controller card."
echo "If lights do not work, check backplane, pins, ports, and cables."
echo

echo "Unmount /media/ubuntu/FAT16 before shutdown."
echo "  umount /media/ubuntu/FAT16"
echo
echo "After checking LED lights, shutdown with:"
echo "  shutdown -h now"
echo "Wait a moment and press the enter key."
echo



# Check for IPMI.
if [ $(dmidecode --type 38 | wc -l) -gt 5 ]
then
  echo "IPMI found!"
fi

echo "Appending brief log..."
cat /tmp/macaddresses.csv >> /tmp/brief.csv



# Log details and push log to FTP server
echo "Shrinking log file..."
sed -i 's/\o015/\n/g' $logfile
dos2unix -f $logfile >/dev/null 2>&1
awk '{gsub(/^[ \t]*$/,"---" NR);}1' $logfile > $logfile.new
echo "Separating GPU logging information"
sed -i 's/[ \t]*errors:/\nerrors:/g' $logfile.new
sed -i 's/[ \t]*proc/\nproc/g' $logfile.new
sed -i 's/[ \t]*temps:/\ntemps:/g' $logfile.new
echo "Removing duplicate lines and cleaning extra newlines"
awk '!x[$0]++' $logfile.new > $logfile
sed -i 's/---[0-9]*//g' $logfile
sed -i ':r;$!{N;br};s/\nUnpacking/Unpacking/g' $logfile
sed -i ':r;$!{N;br};s/\nPreparing to/Preparing to/g' $logfile
sed -i ':r;$!{N;br};s/\nSelecting previously/Selecting previously/g' $logfile
sed -i ':r;$!{N;br};s/\n\nSetting up/Setting up/g' $logfile
sed -i ':r;$!{N;br};s/\nupdate-alternatives/update-alternatives/g' $logfile
sed -i ':r;$!{N;br};s/\nProcessing triggers/Processing triggers/g' $logfile
sed -i ':r;$!{N;br};s/\n\n(Reading database/(Reading database/g' $logfile
echo "Logfile is smaller."

echo "All temporary scripts and logs can be found in the /tmp/ folder."
uptime
if [ -z "$serial" ]
then
  echo Log saved to $logfile
  echo
else
  echo "Renaming log file $logfile to $serial.log..."
  cp $logfile /tmp/$serial.log
  echo "Renaming csv file to $serial.csv..."
  cp /tmp/brief.csv /tmp/$serial.csv
  #logfile=/tmp/$serial.log
  echo "Uploading SO log to ftp..."
  sshpass -p insertlogshere scp -oUserKnownHostsFile=/dev/null \
-oStrictHostKeyChecking=no /tmp/$serial.log user@10.12.17.15:/home/user/logs/
  echo "Uploading SO csv to ftp..."
  sshpass -p insertlogshere scp -oUserKnownHostsFile=/dev/null \
-oStrictHostKeyChecking=no /tmp/$serial.csv user@10.12.17.15:/home/user/logs/
  echo
fi


echo "Uploading timestamped log to ftp..."
sshpass -p insertlogshere scp -oUserKnownHostsFile=/dev/null \
-oStrictHostKeyChecking=no $logfile user@10.12.17.15:/home/user/logs/
echo "Hardware Test is complete.  Check the log, blink lights, & reboot."
