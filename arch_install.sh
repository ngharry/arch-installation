#!/bin/bash
# Copyright (c) Harry Nguyen
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script will set up pre-installation for Arch (such as disk partioning,
# disk mounting, or file system table generating,...)

make_partion() {
	local PARTION_LABEL=$1
	local PARTION_TYPE=$2
	local PARTION_BOOT_NUMBER=$3
	local FIRST_PARTION_SIZE=$4
	local SWAP_SIZE=$5
	parted /dev/sda \
		mklabel $PARTION_LABEL \
		mkpart $PARTION_TYPE 1MiB $(($FIRST_PARTION_SIZE + 1))MiB \
		mkpart primary linux-swap $(($FIRST_PARTION_SIZE + 2))MiB $(($SWAP_SIZE + $FIRST_PARTION_SIZE + 2))MiB \
		mkpart primary ext4 $(($SWAP_SIZE + $FIRST_PARTION_SIZE + 3))MiB 100% \
		set $PARTION_BOOT_NUMBER boot on
}
# disk partioning for UEFI system
gpt_partion() {
	# FAT32 size
	local fat_size=$1

	# Swap size
	local swap_size=$2
	
	# Calculate the exact disk space for swap and fat (in MB)
	# the rest of disk space is taken as / space
	# Usage: partion fat_size swap_size
	# Ex: partion 512 2000 
	parted /dev/sda \
		mklabel gpt \
		mkpart ESP fat32 1MiB $(($fat_size + 1))MiB \
		set 1 boot on \
		mkpart primary linux-swap $(($fat_size + 2))MiB $(($swap_size + $fat_size + 2))MiB \
		mkpart primary ext4 $(($swap_size + $fat_size + 3))MiB 100%
}

# disk partioning for BIOS system
mbr_partion() {
	# Size of /home
	local home_size=$1

	# Swap size
	local swap_size=$2

	# Calculate the exact disk space for swap and home (in MB)
	# the rest of disk space is taken as / space
	# Usage: partion home_size swap_size
	# Ex: partion 8000 2000 
	parted /dev/sda \
		mklabel msdos \
		mkpart primary ext4 1MiB $(($home_size + 1))MiB \
		mkpart primary linux-swap $(($home_size + 2))MiB $(($swap_size + $home_size + 2))MiB \
		mkpart primary ext4 $(($swap_size + $home_size + 3))MiB 100% \
		set 3 boot on
}

format_partion() {
	local FS_TYPE=$1
	$FS_TYPE /dev/sda1
	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2
	swapon /dev/sda2
}

# format_partion() {
# 	if [ -d /sys/firmware/efi ]; then	
# 		mkfs.fat -F32 /dev/sda1
# 	else 
# 		mkfs.ext4 /dev/sda1
# 	fi

# 	mkfs.ext4 /dev/sda3
# 	mkswap /dev/sda2
# 	swapon /dev/sda2
# }

mount_fs() {
	local MOUNT_DIR=$1

	# if [ -d /sys/firmware/efi ]; then
	# 	MOUNT_DIR=/mnt/boot
	# else
	# 	MOUNT_DIR=/mnt/home
	# fi

	mount /dev/sda3 /mnt
	mkdir $MOUNT_DIR
	mount /dev/sda1 $MOUNT_DIR
}

# mount_fs() {
# 	if [ -d /sys/firmware/efi ]; then
# 		MOUNT_DIR=/mnt/boot
# 	else
# 		MOUNT_DIR=/mnt/home
# 	fi

# 	mount /dev/sda3 /mnt
# 	mkdir $MOUNT_DIR
# 	mount /dev/sda1 $MOUNT_DIR
# }

unmount_disk() {
	local UNMOUNT_DIR=$1
	umount $UNMOUNT_DIR
	umount /mnt
}

# unmount_disk() {

# 	if [ -d /sys/firmware/efi ]; then
# 		umount /mnt/boot
# 	else
# 		umount /mnt/home
# 	fi
# 	umount /mnt
# }

install_base() {
	# set mirror
	echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' \
	>> /etc/pacman.d/mirrorlist
	
	# install base and base for developers 
	pacstrap /mnt base base-devel
}

generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

change_root() {
	local execute_script=$1

	# Provide privilege for execute_script
	chmod +x /mnt/$execute_script
	# Run execute_script during chroot
	arch-chroot /mnt ./$execute_script
}

setup() {
	echo "Disk partioning..."
	read -p "How much disk space do you want for swap? " SWAP_SIZE
	# if [ -d /sys/firmware/efi ]; then
	# 	gpt_partion 512 $SWAP_SIZE
	# else
	# 	mbr_partion 5000 $SWAP_SIZE
	# fi
	# echo "Finished."

	# echo "Formating partions..."
	# format_partion
	# echo "Finished."

	# echo "Mounting file system..."
	# mount_fs
	# echo "Finished."
	if [ -d /sys/firmware/efi ]; then
		make_partion gpt 'ESP fat32' 1 512 $SWAP_SIZE
		format_partion 'mkfs.fat -F32'
		mount_fs /mnt/boot
	else
		make_partion msdos 'primary ext4' 3 5000 $SWAP_SIZE
		format_partion mkfs.ext4
		mount_fs /mnt/home
	fi

	# echo "Installing base and base devel..."
	# install_base
	# echo "Finished."

	# echo "Generating file system table..."
	# generate_fstab
	# echo "Finished."

	# curl $configure_sh_link > /mnt/$CONF_NAME
	# change_root $CONF_NAME
}

main() {
	# configure file (execute during chroot)
	local CONF_NAME=configure.sh

	# change branch when downloading configure.sh from github
	local BRANCH=uefi_bios
	local configure_sh_link=https://raw.githubusercontent.com/harrynguyen97/arch-installation/$BRANCH/configure.sh
	
	setup

	# Check if failed or not during chroot
	# if succeed, /mnt/$CONF_NAME would not exist.
	if [ -f /mnt/$CONF_NAME ]; then
		echo 'ERROR: Failed during chroot. Try again.'
		exit
	else
    	echo 'Unmounting filesystems'
    	if [ -d /sys/firmware/efi ]; then
    		unmount_disk /mnt/boot
    	else
    		unmount_disk /mnt/home
    	fi
    	echo 'Finished. You should reboot system for applying changes.'
	fi
}

main