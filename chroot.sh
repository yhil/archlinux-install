#device and vgname given from install.sh script
UUID=$(blkid -s UUID -o value ${device})

read -p "Choose you time zone (e.g: Europe/Paris): " timezone
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime

echo "* Installing base packages"
{
pacman --noconfirm -S base-devel grub efibootmgr dosfstools openssh os-prober mtools linux-headers
} 2>&1 >> /tmp/stdout.log

sed -i "s/\(GRUB_CMDLINE_LINUX\s*=\s*\).*$/\1\"rd.luks.name=${UUID}=root root=\/dev\/${vgname}\/root\"/" /etc/default/grub
sed -i "/GRUB_ENABLE_CRYPTODISK/s/^#//" /etc/default/grub
sed -i "s/\(GRUB_PRELOAD_MODULES\s*=\s*\).*$/\1\"part_gpt part_msdos lvm\"/" /etc/default/grub

sed -i "s/\(HOOKS\s*=\s*\).*$/\1\"base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck\"/" /etc/mkinitcpio.conf

sed -i "/fr_FR.UTF8*/s/^#//" /etc/locale.gen
{
locale-gen
} >> /tmp/stdout.log

read -p "Choose your key mapping: " keymap
echo "KEYMAP=${keymap}" > /etc/vconsole.conf

echo "* Creating initial ramdisk environment"
{
mkinitcpio -p linux
} >> /tmp/stdout.log

echo "*Installing Grub"
{
grub-install --target=x86_64-efi --bootloader-id=grub_uefi modules='lvm crypto' --recheck --efi-directory=/boot

if [[ ! -d /boot/grub/locale/ ]]; then
    mkdir /boot/grub/locale
fi

cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg
} >> /tmp/stdout.log

read -p 'Computer hostname: ' hostname
read -p 'Computer domain name: ' domain
echo "* Setting hostname"
echo "{$hostname}" > /etc/hostname

cat > /etc/hosts << EOF
127.0.0.1 localhost 
::1 localhost 
127.0.1.1 "{$hostname}.${domain}" $hostname 
EOF

read -p "User sudo account name: " username
useradd -m -G wheel -s /bin/bash $username
passwd $username

echo "* Granting sudo access to users in the wheel group"
sed -i "/%wheel\sALL=(ALL)\sALL/s/^#\s//" /etc/sudoers

echo "* Installing users packages"
pacman --noconfirm -S dhclient iw wpa_supplicant networkmanager vim xorg-server plasma kde-applications sddm aws-cli zsh git chromium pepper-flash vagrant nextcloud-client vlc papirus-icon-theme adapta-kde kvantum-theme-adapta tree python-pipenv ntfs-3g xf86-video-intel powerline powerline-fonts tmux base-devel libvirt vde2 dnsmasq bridge-utils openbsd-netcat libvirt qemu

echo "* Enabling services"
systemctl enable NetworkManager
systemctl enable sddm


read -p "Do you want to integrate your machine to a Active Directory domain (yes/no): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "* Script end"
    exit 1
fi

https://raw.githubusercontent.com/yhil/arch-install/master/domain.sh && mv domain.sh /home/domain.sh && chmod +x /home/domain.sh

/bin/bash -c /home/domain.sh

rm /home/domain.sh
rm /home/chroot.sh
