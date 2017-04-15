# hwtestquickgrml.sh
# Test hardware with GRML live GNU/Linux distribution

# Michael McMahon

# To run this script, boot grml and follow these instructions:
# lsblk
# Find the drive partition with this script.
# Mount the partition.  With a syntax like:
# mount /dev/sde2 /mnt
# Run this script with:
# sh /mnt/scripts/hwtestquickgrml.sh

echo \ 
echo Installing packages for stress test...
apt-get update
apt-get install -y ledmon
apt-get install -y lm-sensors
#apt-get install -y memtester
apt-get install -y stress
#apt-get install -y stress-ng
echo \ 

echo Checking load and temperatures before stress test...
uptime
echo \ 
sensors
echo Testing CPU with 55 second stress test...
echo If a kernel panic occurs, check CPU and RAM.
# This cat command in parenthesis pulls the number of CPUs and enters that value into stress as the number of workers.
stress --cpu $(cat /proc/cpuinfo | grep -e processor | wc -l) -v --timeout 55s
echo CPU stress test is complete.
echo \ 
echo Checking load and temperatures after stress test...
uptime
echo \ 
sensors
echo \ 

#echo Testing RAM with memtester...
#sudo memtester $(free -m | head -n 2 | tail -n 1 | awk '{print $7 -30}') 1
#echo \ 

echo Checking RAM capacity...
free -g
echo \ 
echo Checking RAM speed...
dmidecode -t 17 | grep Speed | tail -n 2
echo \ 
echo Check that the RAM capacity and speed are correct.
echo Your RAM clock speed may be different because of CPU or motherboard designs.
echo \ 

echo Checking storage drives...
lsblk
# More drive tests will be added in future releases.
echo \ 

echo Network Interface Cards with ip a...
ip a
echo If network ports are missing, ensure the latest firmware is installed and
echo Intel cards are switched on with BootUtil.exe -flashenable -all
echo If ip a does not work, use ifconfig instead.
# More network tests will be added in future releases.
echo \ 

echo Generating blink.sh...
fdisk -l | grep Disk\ | grep -v -e ram -e identifier -e swap | awk '{print "sleep 1 && sudo ledctl locate=" substr($2, 1, length($2)-1)}' > blink.sh
echo umount /mnt >> blink.sh
echo Test drive LED lights for each drive with:
echo ledctl locate=/dev/sda
echo \ 
echo Or run sh blink.sh to blink all drives with 1 second delay between each drive.
echo If drives fail to light, try again with controller card.
echo If lights do not work, check GPIO cable and backplane pins.
echo \ 

echo Unmount /mnt before shutdown.
echo umount /mnt
echo \ 
echo After checking the output and LED lights, shutdown with:
echo shutdown -h now
echo Wait a moment and press the enter key.
echo \ 
