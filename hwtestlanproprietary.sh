#!/bin/bash

# hwtestlanproprietary.sh
# version 0.9.14
# Test hardware with Debian based GNU/Linux distributions.  Tested on LiveOS
#   Versions of Ubuntu 14.04 Desktop, Ubuntu 16.04 Desktop, and GRML.

# Michael McMahon

# To run this script, boot a Debian based distribution and follow these steps:
# Open a terminal and run this script with:
# sudo bash hwtestlan.sh
# OR
# sudo /bin/bash hwtestlan.sh
# OR
# sudo chmod 755 hwtestlan.sh
# sudo ./hwtestlan.sh



# Initialization checks

# Check for /bin/bash.
if [ "$BASH_VERSION" = '' ]; then
  echo "You are not using bash."
  echo "Use this syntax instead:"
  echo "sudo bash bluearchive.sh"
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
xset s off
xset -dpms
xset s noblank
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false

# Log all stdout to logfile with date.
logfile=/tmp/$(date +%Y%m%d-%H%M).log
exec &> >(tee -a "$logfile")
echo "Starting logfile as $logfile..."
echo \ 



# Updates and dependencies

echo "Adding Universe entries to apt sources list..."
add-apt-repository universe

echo "Installing packages for stress test..."

apt-get purge -y libappstream3 2>/dev/null >> /dev/null
apt-get update 2> /dev/null >> /dev/null
apt-get install -y fio >> /dev/null
apt-get install -y ledmon >> /dev/null
apt-get install -y lm-sensors >> /dev/null
apt-get install -y lsscsi >> /dev/null
apt-get install -y nvme-cli >> /dev/null
apt-get install -y sg3-utils >> /dev/null
apt-get install -y smartmontools >> /dev/null
apt-get install -y sshpass >> /dev/null
apt-get install -y stress >> /dev/null
apt-get install -y sysstat >> /dev/null
apt-get install -y tmux >> /dev/null
# Build temporary directory for storage test logs.
mkdir /tmp/storage



# Motherboard BIOS

echo "Checking dmidecode -t 0..."
dmidecode -t 0


# CPU

echo "Checking CPU model..."
cat /proc/cpuinfo | grep name
echo \ 

echo "Checking load and temperatures before stress test..."
echo \ 
uptime
echo \ 
sensors
echo \ 

echo "If a kernel panic occurs, check CPU and RAM."
echo "Testing CPU with 10 minute stress test..."
stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -t $((60*10))
# stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -t $((60*1))
echo "CPU stress test is complete."
echo \ 

echo "Checking load and temperatures after stress test..."
echo \ 
uptime
echo \ 
sensors
echo \ 



# RAM

echo "Checking RAM capacity in GB..."
free -g
echo "Check that the RAM capacity is correct."
echo "Smaller values are acceptable."
echo "If the difference is more than one stick, check RAM seating."
echo \ 
echo "Checking RAM speed..."
echo \ 
dmidecode -t 17 | grep Speed | grep -v Unknown | tail -n 2
echo \ 
echo "Check that the RAM speed is correct."
echo "Your RAM clock speed may be different because of CPU or motherboard desig\
ns."
echo \ 

echo "Testing RAM with 2 minute stress test..."
# stress --vm-bytes 1k --vm-keep -m 1 -t 120
stress --vm-bytes $(cat /proc/meminfo | grep mF | awk '{printf "%d\n", $2 * \
0.9}')k --vm-keep -m 1 -t 120
# stress --vm-bytes $(cat /proc/meminfo | grep mF | awk '{printf "%d\n", $2 * \
#0.9}')k --vm-keep -m 1 -t 30
echo "2 minute stress test complete.  Use memtest+."
echo \ 

# echo "Testing RAM with memtester..."
# Lock times out on 256GB of memory.  Use memtest+.
# sudo memtester $(free -m | head -n 2 | tail -n 1 | awk '{print $7 * 0.9}') 1
# echo \ 



# Storage

echo "Checking storage drives..."
lsblk

# Backplane firmware
# xtools can be found on the Supermicro ftp at:
# ftp://ftp.supermicro.com/utility/ExpanderXtools_Lite/Linux/SAS3ExpanderXtools\
#_v3.3b_Linux_version.zip
echo "Downloading xtools..."
cd /tmp
wget -q ftp://10.12.17.15/pub/software/linux/SAS3ExpanderXtools_v3.3b.zip
echo "Extracting xtools..."
unzip -qq -o SAS3ExpanderXtools_v3.3b.zip
chmod -R 755 Linux
cd Linux
echo "Retrieving backplane firmware..."

if [ $(lsscsi -g | grep -I enclos | wc -l) -eq 2 ]
then
  echo "Two backplanes found!"
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==1') --join | grep enclosure | awk '{print $6}') get ver 0 | grep Firm
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==1') --join | grep enclosure | awk '{print $6}') get ver 3 | tail -n 10
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==2') --join | grep enclosure | awk '{print $6}') get ver 0 | grep Firm
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==2') --join | grep enclosure | awk '{print $6}') get ver 3 | tail -n 10
fi

if [ $(lsscsi -g | grep -I enclos | wc -l) -eq 1 ]
then
  echo "One backplane found!"
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==1') --join | grep enclosure | awk '{print $6}') get ver 0 | grep Firm
  ./g3Xflash -i $(sg_ses $(lsscsi -g | grep -i enclos | awk '{print $7}' | \
awk 'NR==1') --join | grep enclosure | awk '{print $6}') get ver 3 | tail -n 10
fi

echo "Generating smartmon.sh..."
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print \
"smartctl --xall " substr($2, 1, length($2)-1) " | grep -e Firmware -e \
Rotation -e Model"}' > smartmon.sh
echo "Executing smartmon.sh..."
sh smartmon.sh
echo \ 

echo "Checking for Intel SSD drives..."
sed 's/-e Firmware -e Rotation -e Model/-i intel 2>\/dev\/null >> intel.txt/g' \
smartmon.sh > intelcheck.sh
bash intelcheck.sh
touch intel.txt
if [ $(cat intel.txt | wc -l) -gt 0 ]
then
  echo "Intel SSD drives found!"
  echo "Downloading Intel firmware for 4500 and 4600 tools..."
  wget -q ftp://10.12.17.15/pub/software/firmware/intel/p4500/Intel_SSD_Data_Ce\
nter_Tool_3.0.10_Linux.zip
  unzip -qq Intel_SSD_Data_Center_Tool_3.0.10_Linux.zip
  dpkg -i isdct_3.0.10.400-17_amd64.deb
  isdct show -intelssd
  for ssddrives in $(isdct show -intelssd | grep Index | cut -d : -f 2)
  do
    echo Y | isdct load -intelssd $ssddrives
  done
fi
echo "If Intel drives were expected and not updated, check that the controller"
echo "card is set to JBOD."
# Based on https://gist.github.com/Miouge1/4ecced3a2dcc825bb4b8efcf84e4b17b

echo "Checking nvme drives..."
nvme list
echo "Generating nvme.sh..."
cd /tmp
fdisk -l | grep 'Disk\ .*nvme' | awk '{print "nvme smart-log " substr($2, 1, \
length($2)-1)}' > nvme.sh
echo "Executing nvme.sh..."
sh nvme.sh
echo \ 

# WIP: Create temporary file with all unpartitioned drives that are not flash or
#   SSD drives.
# cat /proc/partitions | grep -v -e ram -e sr -e dm -e blocks -e '^$' | awk '{ \
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
  cd /tmp
  wget -q ftp://10.12.17.15/pub/software/raid/SAS3IRCU_P15.zip
  unzip -qq SAS3IRCU_P15.zip
  cd SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x64_rel/
  chmod 755 sas3ircu
  ./sas3ircu list
  ./sas3ircu 0 display
fi

if [ $(lspci | grep 3224 | wc -l) -gt 0 ]
then
  echo "HBA 3008 found!"
  cd /tmp
  wget -q ftp://10.12.17.15/pub/software/raid/SAS3IRCU_P15.zip
  unzip -qq SAS3IRCU_P15.zip
  cd SAS3IRCU_P15/sas3ircu_rel/sas3ircu/sas3ircu_linux_x64_rel/
  chmod 755 sas3ircu
  ./sas3ircu list
  ./sas3ircu 0 display
fi

if [ $(lspci | grep 3108 | wc -l) -gt 0 ]
then
  echo "SAS3108 found!"
  cd /tmp
  echo "Downloading StorCLI..."
  wget -q https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-co\
ntrollers-common-files/1.21.16_StorCLI.zip
  echo "extracting StorCLI..."
  unzip -qq -o 1.21.16_StorCLI.zip
  cd versionChangeSet/univ_viva_cli_rel
  unzip -qq -o storcli_All_OS.zip
  cd storcli_All_OS/Ubuntu
  # cd storcli_All_OS//Linux # RPM
  echo "Installing StorCLI to the /opt/MegaRAID/storlci/ folder..."
  dpkg -i storcli_1.21.06_all.deb
  # rpm -i storcli_1.21.06_all.rpm # RPM
  ln -s /opt/MegaRAID/storcli/storcli64 /usr/bin/storcli
  /opt/MegaRAID/storcli/storcli64 /c0 show all
  /opt/MegaRAID/storcli/storcli64 /c0 /eall /sall show
  echo "Key:"
  echo 'UGood-Unconfigured Good|UBad-Unconfigured Bad'
  echo 'Onln-Online|Offln-Offline'
  echo 'Optl=Optimal|DNOpt=DG NotOptimal|VNOpt=VD NotOptimal'
  echo 'Rbld=Rebuild|Frgn=Foreign configuration'
  echo 'Msng=Missing|Pdgd=Partially Degraded|dgrd=Degraded'
  echo \ 
fi

if [ $(lspci | grep Atto | wc -l) -gt 0 ]
then
  echo "Installing Atto drivers..."
  cd /tmp
  wget -q https://www.atto.com/software/files/drivers/lnx_drv_esashba4_125.tgz \
2> /dev/null
  tar xzf lnx_drv_esashba4_125.tgz
  cd lnx_drv_esashba4_125
  sudo sh install.sh auto
  cd ..
  echo \ 
  echo "Testing drives on Atto card..."
  /usr/local/sbin/atinfo -c 1 -i all
  echo \ 
fi

# hdparm
echo "Generating hdparm.sh..."
cd /tmp
if [ $(lsblk -V | grep 2.29.2 | wc -l) -gt 0 ]
then
  # SSDs and flash drives are excluded.
  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e usb -e 'sda ' -e 'sdb '\
-e loop -e NAME | awk '{ print "sudo hdparm -tT /dev/" $1 " > /tmp/storage/"\
$1 " &" }' > hdparm.sh
  echo "hdparm tests will start in parallel.  Do not start any other drive test\
s until complete."
else
  if [ $(cat /etc/*-release | grep 16.04 | wc -l) -gt 4 ]
  then
    # SSDs and flash drives are excluded.
    lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e usb -e 'sda ' -e \
'sdb ' -e loop -e NAME | awk '{ print "sudo hdparm -tT /dev/" $1 " \
> /tmp/storage/" $1 " &" }' > hdparm.sh
    echo "hdparm tests will start in parallel."
    echo "Do not start any other drive tests until complete."
  fi
  if [ $(cat /etc/*-release | grep 14.04 | wc -l) -gt 4 ]
  then
    # SSDs are excluded.  Older version of lsblk does not have tran.
    lsblk -d -o name,rota | grep -v -e 0 -e sr -e loop -e NAME | awk '{ print \
"sudo hdparm -tT /dev/" $1 " > /tmp/storage/" $1 " &" }' > hdparm.sh
  fi
fi
echo "Testing HDDs with hdparm..."
sh hdparm.sh
echo \ 

# dd
# echo "WARNING: If the OS comes up as anything else other than sda and sdb,"
# echo "this will be destructive."
# echo "WARNING: This can be destructive.  Use at your own risk."
#if [ $(cat /etc/*-release | grep 16.04 | wc -l) -gt 4 ]
#then
#  echo "Testing HDDs with dd..."
#  # SSDs and flash drives are excluded.
#  cd /tmp
#  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e 'sda ' -e 'sdb ' -e \
#usb -e loop -e NAME | awk '{ print "dd bs=4M count=2048 if=/dev/zero \
#of=/dev/" $1 " conv=fdatasync status=progress > /tmp/storage/dd" $1 " &" \
#}' > ddtest.sh
#  sudo sh ddtest.sh
#  echo "Use 'iostat' to see activity on drives."
#  echo "Use 'ps aux | grep fio' to see if fio is still running."
#fi
#

# fio
echo "Generating fio2hourtest.sh..."
echo "WARNING: If the OS is NOT on sda and sdb, this will be destructive."
echo "WARNING: This can be destructive.  Use at your own risk."
if [ $(cat /etc/*-release | grep 16.04 | wc -l) -gt 4 ]
then

  # SSDs and flash drives are excluded.
  cd /tmp
  echo "echo 'Stopping hdparm...'" > fio2hourtest.sh
  echo "pkill hdparm" >> fio2hourtest.sh
  echo "echo 'Testing HDDs with fio...'" >> fio2hourtest.sh
  echo "echo 'WARNING: If the OS is NOT on sda and sdb, this will be \
destructive.'" >> fio2hourtest.sh
  echo "echo 'WARNING: This can be destructive.  Use at your own risk.'" \
    >> fio2hourtest.sh
  lsblk -S -d -o name,rota,tran | grep -v -e 0 -e sr -e 'sda ' -e 'sdb ' -e \
usb -e loop -e NAME | awk '{ print "fio --name=readwrite --ioengine=libaio \
--iodepth=1 --rw=readwrite --bs=4k --direct=1 --size=512M --numjobs=8 \
--filename=/dev/" $1 " --time_based=7200 --runtime=7200 --group_reporting \
| grep io > /tmp/storage/fio" $1 " &"}' >> fio2hourtest.sh
  # sudo sh fio2hourtest.sh # This can be run from longstress.sh or by
  #   uncommenting tmux line below.
fi
# With help of @tfindelkind from http://tfindelkind.com/2015/08/10/fio-flexible\
#   -io-tester-part5-direct-io-or-buffered-page-cache-or-raw-performance/
# https://wiki.mikejung.biz/Benchmarking#Install_Fio_on_Ubuntu_14.10
# https://tobert.github.io/post/2014-04-28-getting-started-with-fio.html
# https://tobert.github.io/post/2014-04-17-fio-output-explained.html

echo "Storage test logs can be found in the /tmp/storage/ folder."
echo \ 



# tmux and Long stress test
cd /tmp
echo stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -t 4h \
> cpu.sh
echo "pkill top" >> cpu.sh
echo "pkill iostat" >> cpu.sh
echo "pkill tmux" >> cpu.sh
echo "exit" >> cpu.sh
echo stress --vm-bytes $(cat /proc/meminfo | grep mF | awk '{printf "%d\n", $2 \
* 0.9}')k --vm-keep -m 1 -t 4h > ram.sh
echo "exit" >> ram.sh
echo "iostat -ctd 2" >> fio2hourtest.sh
echo "exit" >> fio2hourtest.sh
# tmux new-session -d -s hwtest \; send-keys 'sh /tmp/cpu.sh && exit' 'C-m' \; \
#   rename-window 'hwtest' \; select-window -t hwtest:0 \; split-window -h \; \
#   send-keys 'sh /tmp/ram.sh && exit' 'C-m' \; split-window -v -t 0 \; \
#   send-keys 'top && exit' 'C-m' \; split-window -v -t 1 \; send-keys 'sh \
#   /tmp/fio2hourtest.sh && exit' 'C-m' \; attach-session -t hwtest
echo "Generating longtest.sh..."
echo "tmux new-session -d -s hwtest \; send-keys 'sh /tmp/cpu.sh && exit' \
'C-m' \; rename-window 'hwtest' \; select-window -t hwtest:0 \; split-window \
-h \; send-keys 'sh /tmp/ram.sh && exit' 'C-m' \; split-window -v -t 0 \; \
send-keys 'top && exit' 'C-m' \; split-window -v -t 1 \; send-keys 'sh \
/tmp/fio2hourtest.sh && exit' 'C-m' \; attach-session -t hwtest" \
> longstress.sh
echo "To run a longer 4 hour stress test on the CPU, RAM, and drives"
echo "simutaneously, run sudo sh /tmp/longstress.sh"



# Networking

if [ $(lspci | grep Mellanox | wc -l) -gt 0 ]
then
  echo "Mellanox card found.  Installing dependencies..."
  apt-get install -y build-essential >> /dev/null
  apt-get install -y dkms >> /dev/null
  cd /tmp
  echo "Downloading Mellanox mft package..."
  # wget -q http://www.mellanox.com/downloads/MFT/mft-4.6.0-48-x86_64-deb.tgz
  wget -q http://www.mellanox.com/downloads/MFT/mft-4.8.0-26-x86_64-deb.tgz
  # tar zxf mft-4.6.0-48-x86_64-deb.tgz
  tar zxf mft-4.8.0-26-x86_64-deb.tgz
  # cd mft-4.6.0-48-x86_64-deb
  cd mft-4.8.0-26-x86_64-deb
  # sh install.sh
  dpkg -i ./DEBS/mft-4*
  dpkg -i ./DEBS/mft-o*
  apt-get update
  dpkg -i ./SDEBS/k*
  mst start
  sudo mlxfwmanager --query
  echo "Updating Mellanox firmware..."
  mlxfwmanager --online -u -y
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
cat /sys/class/net/*/address | grep -v 0:00:00:0
cat /sys/class/net/*/address | grep -v 0:00:00:0 | sed -n -e \
'H;${x;s/\n/,/g;s/^,//;p;}' > /tmp/macaddresses.csv
# Create a csv file of all Mac Addresses (Excluding IPMI)
echo "If network ports are missing, ensure the latest firmware is installed and"
echo "Intel cards are switched on with BootUtil.exe -flashenable -all"
echo \ 

echo "Generating ethtest.sh..."
cd /tmp
echo "Testing network cards with ethtool..." > ethtest.sh
ip a | awk '{ print "sleep 1 && sudo ethtool -t " substr($2, 1, length($2)-1) \
" 2> /dev/null | grep -v -e extra -e result -e Link"}' | grep -v -e fore -e : \
-e se -e /\  -e /2 -e lo >> ethtest.sh
echo "Key: 0 means PASS." >> ethtest.sh
echo "Network connection may be broken after ethtool tests." >> ethtest.sh
echo "Reboot to fix connection." >> ethtest.sh
echo "To test the network cards, run:"
echo "  sudo sh /tmp/ethtest.sh"
echo "This may break your network connection until you reboot."
# If sending logs to a central server, skip ethtest.sh
echo \ 



# PCI Devices

echo "Listing all NVIDIA cards..."
echo "Card models are shown by a four character code instead of plaintext."
echo "For example, NVIDIA Tesla P40 will show the code 1b38."
echo "For a complete list of NVIDIA card codes, check the pci-ids at:"
echo "http://pci-ids.ucw.cz/read/PC/10de"
lspci | grep -i nvidia​
# Explanation of this command:
# lspci - list all PCI devices​
# | -  Pipelines - The standard output of the first command is connected via
#    a pipe to the  standard  input of the second command.
# grep - print lines matching a pattern
#   -i, --ignore-case
#   Ignore case distinctions in both the PATTERN and the input files.
#     (-i is specified by POSIX.)
echo \ 

echo "Listing all PCI devices..."
lspci
echo \ 



# LEDs

echo "Generating blink.sh..."
cd /tmp
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print \
"sleep 1 && sudo ledctl locate=" substr($2, 1, length($2)-1)}' > blink.sh
echo "Test drive LED lights for each drive with:"
echo "ledctl locate=/dev/sda"
echo \ 
echo "Run sh /tmp/blink.sh to blink all drives with 1 second delay between \
drives."
echo "If drives fail to light, try again with controller card."
echo "If lights do not work, check backplane, pins, ports, and cables."
echo \ 

echo "Unmount /media/ubuntu/FAT16 before shutdown."
echo "  sudo umount /media/ubuntu/FAT16"
echo \ 
echo "After checking LED lights, shutdown with:"
echo "  sudo shutdown -h now"
echo "Wait a moment and press the enter key."
echo \ 



# IPMICFG can be downloaded from
#   https://www.supermicro.com/solutions/SMS_IPMI.cfm
#   or ftp://ftp.supermicro.com/utility/IPMICFG/
# By using this script, you are agreeing to Supermicro's EULA agreement.

# Check for IPMI.
if [ $(sudo dmidecode --type 38 | wc -l) -gt 5 ]
then
  echo "Downloading IPMICFG from LAN..."
  cd /tmp/
  wget ftp://10.12.17.15/pub/software/ipmi/utilities/IPMICFG_1.26.0_20161227.\
zip 2>/dev/null
  echo \ 

  echo "Extracting IPMICFG..."
  unzip -qq -o IPMICFG_1.26.0_20161227.zip
  cd IPMICFG_1.26.0_20161227/Linux/64bit
  chmod 755 IPMICFG-Linux.x86_64
  echo \ 

  echo "Checking IPMI version..."
  ./IPMICFG-Linux.x86_64 -ver
  echo "Testing IPMI..."
  ./IPMICFG-Linux.x86_64 -selftest
  echo "IPMI selftest complete."
  ./IPMICFG-Linux.x86_64 -sel list
  ./IPMICFG-Linux.x86_64 -m
  ./IPMICFG-Linux.x86_64 -fru 2m
  ./IPMICFG-Linux.x86_64 -fru 2p
  ./IPMICFG-Linux.x86_64 -fru 2s

  echo "Enter or reenter FRU to set FRU and logfile."
  read -p 'Enter system serial # ' serial
  if [ -z "$serial" ]
  then
    echo "\$serial is empty.  Skipping FRU..."
  else
    ./IPMICFG-Linux.x86_64 -fru pat $serial
  fi
  echo \ 

  ./IPMICFG-Linux.x86_64 -fru list
  echo "Check FRU."
  echo "If FRU is incorrect, rerun fru.sh!"
  echo "If kcs_error_exit appears, system may not have IPMI."
  echo \ 
fi



# Log details and push log to FTP server
echo "All temporary scripts and logs can be found in the /tmp/ folder."
uptime
if [ -z "$serial" ]
then
  echo Log saved to $logfile
  echo \ 
else
  echo "Log file $logfile renamed to $serial."
  cp $logfile /tmp/$serial.log
  #logfile=/tmp/$serial.log
  sshpass -p insertpasswordhere scp -oUserKnownHostsFile=/dev/null \
-oStrictHostKeyChecking=no /tmp/$serial.log user@10.12.17.15:/home/user/logs/
  echo \ 
fi


sshpass -p insertpasswordhere scp -oUserKnownHostsFile=/dev/null \
-oStrictHostKeyChecking=no $logfile user@10.12.17.15:/home/user/logs/
echo "Log files are copied to FTP server."
