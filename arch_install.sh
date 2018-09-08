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

# Partion /dev/sda
# Usage: 
# UEFI: make_partion gpt 'ESP fat32' 1 512 $SWAP_SIZE
# BIOS: make_partion msdos 'primary ext4' 3 $HOME_SIZE $SWAP_SIZE
partion_disks() {
	# label for partions
	local PARTION_LABEL=$1

	# partion type
	local PARTION_TYPE=$2

	# set which partion is boot
	local PARTION_BOOT_NUMBER=$3

	# Specifies size of first partion and swap partion
	local FIRST_PARTION_SIZE=$4
	local SWAP_SIZE=$5

	# Calculate exact value in MiB of disk partions
	parted /dev/sda \
		mklabel $PARTION_LABEL \
		mkpart $PARTION_TYPE 1MiB $(($FIRST_PARTION_SIZE + 1))MiB \
		mkpart primary linux-swap $(($FIRST_PARTION_SIZE + 2))MiB $(($SWAP_SIZE + $FIRST_PARTION_SIZE + 2))MiB \
		mkpart primary ext4 $(($SWAP_SIZE + $FIRST_PARTION_SIZE + 3))MiB 100% \
		set $PARTION_BOOT_NUMBER boot on
}

# Make filesystem
# Usage:
# UEFI: format_partion 'mkfs.fat -F32'
# BIOS: format_partion mkfs.ext4
format_partions() {
	local FS_TYPE=$1

	$FS_TYPE /dev/sda1
	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2
	swapon /dev/sda2
}

# Mount file system
# Usage:
# UEFI: mount_fs /mnt/boot
# BIOS: mount_fs /mnt/home
mount_fs() {
	local MOUNT_DIR=$1

	mount /dev/sda3 /mnt
	mkdir $MOUNT_DIR
	mount /dev/sda1 $MOUNT_DIR
}

# Unmount file system
# Usage:
# UEFI: unmount_fs /mnt/boot
# BIOS: unmount_fs /mnt/home
unmount_fs() {
	local UNMOUNT_DIR=$1
	umount $UNMOUNT_DIR
	umount /mnt
}

chroot_to_configuration() {
	local execute_script=$1

	# Provide privilege for execute_script
	chmod +x /mnt/$execute_script

	# Run execute_script during chroot
	arch-chroot /mnt ./$execute_script
}

pre_install() {
	echo "Disk partioning..."
	read -p "How much disk space do you want for swap? " SWAP_SIZE

	if [ -d /sys/firmware/efi ]; then
		partion_disks gpt 'ESP fat32' 1 512 $SWAP_SIZE
		echo "Finished partioning."

		echo "Making file system..."
		format_partions 'mkfs.fat -F32'
		echo "Finished making file system."

		echo "Mounting file system..."
		mount_fs /mnt/boot
		echo "Finished mounting file system."
	else
		read -p "How much disk space do you want for /home? " HOME_SIZE
		partion_disks msdos 'primary ext4' 3 $HOME_SIZE $SWAP_SIZE

		echo "Making file system..."
		format_partions mkfs.ext4
		echo "Finished making file system."

		echo "Mounting file system..."
		mount_fs /mnt/home
		echo "Finished mounting file system."
	fi
}

install_base() {
	# set mirror
	echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' \
	>> /etc/pacman.d/mirrorlist

	# install base and base for developers 	
	echo "Installing base and base devel..."
	pacstrap /mnt base base-devel
	echo "Finished."
}

configure() {
	echo "Generating file system table..."
	genfstab -U /mnt >> /mnt/etc/fstab
	echo "Finished."

	local CONF_NAME=$1

	# change branch when downloading configure.sh from github
	local BRANCH=redesign

	local configure_sh_link=https://raw.githubusercontent.com/harrynguyen97/arch-installation/$BRANCH/$CONF_NAME

	# Download configure.sh for configuring system
	curl $configure_sh_link > /mnt/$CONF_NAME

	# Execute configure.sh during change root
	chroot_to_configuration $CONF_NAME
}

main() {
	local CONF_NAME=configure.sh

	pre_install
	install_base
	configure $CONF_NAME

	# Check if failed or not during chroot
	# if succeed, /mnt/$CONF_NAME would not exist.
	if [ -f /mnt/$CONF_NAME ]; then
		echo 'ERROR: Failed during chroot. Try again.'
		exit
	else
    	echo 'Unmounting filesystems'
    	if [ -d /sys/firmware/efi ]; then
    		unmount_fs /mnt/boot
    	else
    		unmount_fs /mnt/home
    	fi
    	echo 'Finished. You should reboot system for applying changes.'
	fi
}

main
