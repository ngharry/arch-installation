# Automatic Arch Linux Installation

This is a bash script used for automating Arch Linux installation process. *At the time, this script is just used for Arch Linux in VirtualBox.*

## What can this script do? 
- Disk partion (in both UEFI and BIOS).
- Make file system.
- Mount install disk.
- Install base and base devel.
- Generate file system table
- `arch-chroot` and execute configuration script which can do the following:
  * Set up time zone (Australia/Adelaide)
  * Set up language (en_US.UTF-8)
  * Set up host name.
  * Install networkmanager and enable NetworkManager.service.
  * Set root password.
  * Create users.
  * Install boot loader.
  * Install vim, zsh, bash-completion, sudo, zsh-completion, git.
  * Install yaourt.
  * Upgrade whole system.

## Prerequisites
1. A virtual environment (VirtualBox, VmWare, etc.). I am testing this script using VirtualBox.
2. Download Arch OS ISO [here](https://mirror.aarnet.edu.au/pub/archlinux/iso/2018.08.01/archlinux-2018.08.01-x86_64.iso)
3. Create a virtual machine. System recommended:
  * At least 10GB for virtual hard disk.
  * At least 512MB RAM.
  * If you want to use UEFI, under Settings > System > Motherboard, tick `Enable EFI (special OSes only).`. Otherwise, the system will use BIOS.
4. Boot into live CD of Arch (with UEFI, be patient, it could take a while with a black screen).

## Installing
Download `arch_install.sh` to the live Arch Linux environment:

```
curl -O https://raw.githubusercontent.com/harrynguyen97/arch-installation/master/arch_install.sh
```

Set execute permission for `arch_install.sh`:

```
chmod +x arch_install.sh
```

Run `arch_install.sh`:
```
./arch_install.sh
```

When you are asked for swap disk size, enter swap size in MB. Example below illustrates creating 2GB swap:
```
How much disk space do you want for swap? 2000
```

For BIOS system, you will be asked for specifying /home size. Example:
```
How much disk space do you want for /home? 5000
```

You will be asked for entering host name, root password, creating users. For example:

**Host name**
```
Enter host name: arch-os
```

**Setting root password**
```
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
```
*If you enter 2 unmatched passwords, you will be asked for entering again.*

**Create users**

You will be asked if you want to create user or remain root privilege:
```
Do you want to create user? (Y/N) Y
```
Type `Y` or `N` (in UPPERCASE) depends on what you want.


If you choose to create user, you will need to enter username and password.
```
Username: harry
Changing password for harry.
(currrent) UNIX password:
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
Do you want to create more user? (Y/N): N
```
*If any errors occur during creating user, you will be asked for re-enter username and password.*
*When you are asked if you want to create more user, type `Y` or `N` (in UPPER CASE).*


You will be asked if you want to install KDE (my favorite DE):
```
Do you want to install KDE? (Y/N) Y
```

If no error occurs, after finishing installation process, you can reboot your system.


## UEFI Only
**[IMPORTANT]** After rebooting and playing around with your new system, shutdown and **REMEMBER to remove disk from Virtual Drive** under Settings > Storage > Attributes, click the disk icon next to `Optical Drive:` and choose `Remove Disk from Virtual Drive`. If you do not do this, next time the system will boot to live CD again.

## TODO List
- [x] Install yaourt.
- [x] Allow both BIOS and UEFI to run this script.
- [x] Ask if user want to create user or not.
- [ ] Install X Server.
- [ ] Install Desktop Environment and Display Manager.
- [ ] Install themes.
- [ ] Install Sublime Text.
- [ ] Install necessary packages (web browser, git, etc.).
- [ ] Install fonts.

- [ ] Figure out why Arch does not work after installing KDE/SDDM and Deepin/lightdm.

## Bug Reporting

- During installation process in VirtualBox, pressing `PrtScr` would lead to an error.
[Add picture here.]

- Arch does not work after installing KDE/SDDM or Deepin/lightdm.

**Description:**

With deepin and lightdm: the login screen stays white, after I managed to login, a white blank screen shows up and I could not click anything.
[Add picture here.]

With KDE and SDDM: the mouse and touchpad(right-click) are stucked at 1 point.