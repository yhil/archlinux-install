#!/bin/bash


echo "*Verify EFI firmware"
{
if [[ -d /sys/firmware/efi ]]; then
    eficomputer="0"
else
    eficomputer="1"
    exit 1
fi
} >> /root/stdout.log

echo "* Ensure the clock is accurate" 

{
timedatectl set-ntp true
} >> /root/stdout.log

fdisk -l

read -p "Disk to use for the installation (e.g: '/dev/sda'): " device

echo "* Partitioning disk"
parted $device mklabel gpt
sgdisk $device -n=1:0:+600M -t 1:ef00
sgdisk $device -n=2:0:0


echo "* Initializing LUKS partition "
cryptsetup luksFormat ${device}2


echo "* Opening cryptoluks ${device}2 with cryptlvm name"
cryptsetup open ${device}2 cryptlvm


mapper=/dev/mapper/cryptlvm

echo "* Creating physical volume for lvm on ${mapper}"

{
pvcreate $mapper
} >> /root/stdout.log

read -p "Volume group name: " vgname

echo "* Creating volume group ${vgname} on ${mapper}"
{
vgcreate $vgname $mapper
} >> /root/stdout.log


swap=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')
swap=$((${swap}/2000))"M"

echo "* Creating swap, root, home logical volumes on ${vgname}"
{
lvcreate -L $swap $vgname -n swap
lvcreate -L 100G $vgname -n root
lvcreate -l 100%FREE $vgname -n home
} >> /root/stdout.log

echo "* Formating root, home and swap volumes"
{
mkfs.ext4 /dev/${vgname}/root
mkfs.ext4 /dev/${vgname}/home
mkswap /dev/${vgname}/swap
} >> /root/stdout.log

echo "* Mounting root and home volumes in /mnt & /mnt/home"
{
mount /dev/${vgname}/root /mnt
mkdir /mnt/home
mount /dev/${vgname}/home /mnt/home
} >> /root/stdout.log

echo "* Activating swap volume"
{
swapon /dev/${vgname}/swap
} >> /root/stdout.log

echo "* Partitioning boot partition on /dev/${device}1"
{
mkfs.fat -F 32 ${device}1
} >> /root/stdout.log

echo "* Mounting boot partition on /mnt/boot"
{
mkdir /mnt/boot
mount ${device}1 /mnt/boot
} >> /root/stdout.log

echo "* Installing essential packages"
{
pacstrap /mnt base linux linux-firmware lvm2
} >> /root/stdout.log

{
echo "* Generating fstab"
{
genfstab -U -p /mnt >> /mnt/etc/fstab
} >> /root/stdout.log

echo "* Setting chroot.sh script"
{
wget https://raw.githubusercontent.com/yhil/arch-install/master/chroot.sh && mv chroot.sh /mnt/home/chroot.sh && chmod +x /mnt/home/chroot.sh 
} >> /root/stdout.log

sed -i "1 i\device=${device}"
sed -i "1 i\vgname=${vgname}"

echo "* Changing root to new system and starting chroot.sh"
arch-chroot /mnt /bin/bash -c /home/chroot.sh
