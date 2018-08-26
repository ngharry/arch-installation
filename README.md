# Automatic Arch Linux Installation

This is a bash script used for automating Arch Linux installation process. *At the time, this script is just used for Arch Linux in VirtualBox*

## Getting Started

Download `arch_install.sh` to the live Arch Linux environment:

```
curl -O https://raw.githubusercontent.com/harrynguyen97/arch-installation/master/arch_install.sh
```

Set execute permission for `arch_install.sh`:

```
chmod +x arch_install.sh
```

## Prerequisites
1. A virtual environment (VirtualBox, VmWare,..). I am testing this script using VirtualBox.
2. Arch OS ISO [download here](https://mirror.aarnet.edu.au/pub/archlinux/iso/2018.08.01/archlinux-2018.08.01-x86_64.iso)
3. Create a virtual machine. System recommended:
  * At least 20GB for virtual hard disk.
  * At least 1GB RAM
  * Under Settings > System > Motherboard, tick `Enable EFI (special OSes only). 

4. Boot into live CD of Arch (be patient, it could take a while with a black screen).

## Installing
