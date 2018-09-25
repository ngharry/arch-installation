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
  * Install vim, zsh, git, X server, ssh, virtualbox guest utilities.
  * Install yaourt.

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
curl -O https://raw.githubusercontent.com/ngharry/arch-installation/master/arch_install.sh
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

If no error occurs, after finishing installation process, you can reboot your system.


## UEFI Only
**[IMPORTANT]** After rebooting and playing around with your new system, shutdown and **REMEMBER to remove disk from Virtual Drive** under Settings > Storage > Attributes, click the disk icon next to `Optical Drive:` and choose `Remove Disk from Virtual Drive`. If you do not do this, next time the system will boot to live CD again.

## TODO
- [x] Install yaourt.
- [x] Allow both BIOS and UEFI to run this script.
- [x] Ask if user want to create user or not.
- [x] Install X Server.
- [x] Install Sublime Text.
- [x] Install necessary packages (web browser, git, etc.).
- [x] Install fonts (Adobe Source Code, Hack).
- [ ] Configure full screen tty console in Arch.
- [x] Figure out why Arch does not work after installing KDE/SDDM and Deepin/lightdm.
- [x] Copy, paste, share clipboard from guest to host.
- [x] At the end of installation process, obviously, `rm configure.sh` is not working. Figure it out some time. (Silly mistake: the directory which the script is working on is /, the remove command should be `rm /configure.sh` instead of `rm configure.sh`.) 

## Bug Reporting

- During installation process in VirtualBox, pressing `PrtScr` would lead to an error.
[Add picture here.]

- Error: `invalid or corrupted package (PGP signature)` when installing some packages.

  **Solved**

  Install `archlinux-keyring` and update your system.

  ```
  sudo pacman -S archlinux-keyring
  sudo pacman -Syu
  ``` 

  and install your desire packages again.


- Arch does not work after installing KDE/SDDM or Deepin/lightdm.

  *Description:*

  With deepin and lightdm: the login screen stays white, after I managed to login, a white blank screen shows up and I could not click anything.

  [Add picture here.]

  With KDE and SDDM: the mouse and touchpad(right-click) are stucked at 1 point.

  **Solved**

  Installing plasma-meta and kde-applications-meta will solve this problem.

  When I installed KDE, I just install plasma in the form of a group, which did not have enough dependencies for installing KDE.


- Can not launch application without Desktop Environment (DE) when setting full-screen TTY.

  *Description:*

  I managed to set TTY to full screen by modify `/etc/default/grub` and change `GRUB_CMDLINE_LINUX_DEFAULT="quiet"` to `GRUB_CMDLINE_LINUX_DEFAULT="quiet video=1920x1080"` and then `grub-mkconfig -o /boot/grub/grub.cfg`. However, when I try to launch application without DE, it seems to have some problems with X server. Eg: `firefox` can not start in full-screen even though I use `exec firefox 1920x1080+0+0` in `/etc/X11/xinit/xinitrc`.

  When I delete `video=1920x1080`, then `grub-mkconfig -o /boot/grub/grub.cfg`, things works well again.

## References

[Arch Linux Wiki](https://wiki.archlinux.org/)

See also: [My Arch Linux Configuration](https://gist.github.com/ngharry/9a884f751da106573bd14ff3fb41f5f7)