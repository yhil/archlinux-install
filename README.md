# ArchLinux Install
ArchLinux installation is a nice way to learn about a Linux distribution.
But if you setup computers often and you want the same result every time, you'll want to automate the process.

This is a group of scripts to install ArchLinux EFI Computer. This include:

### Main.sh:
- NTP enable
- Lvm partitioning, encryption and ext4 formating
- Fstab generation
- Essential packages installation

### Chroot.sh:
- Set time zone
- Base packages installation
- FLocale generation
- Grub installation
- Set computer name and domain
- hosts file configuration
- Add sudo user account
- KDE's desktop environment and users tool packages (e.g: vlc, chromium, git, vagrant...)


### Domain.sh:
- hosts file update
- Ntp configuration
- Kerberos configuration
- Winbind configuration
- Samba configuration
- Pam system-auth configuration
- Pam su configuration

# Usage:
2. Boot your live environment
3. Install wget
4. Download the script from main.sh script from github
```wget https://raw.githubusercontent.com/yhil/arch-install/master/main.sh```
5. Change the script permission to allow execution
```chmod +x main.sh```
6. Start the script
```.\main.sh```
