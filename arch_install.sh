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
partion() {
	# Swap size
	local swap_size=$2

	if [ -d /sys/firmware/efi ]; then
		# FAT32 size
		local fat_size=$1

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
	else
		# size of home
		local home_size=$1
		
		parted /dev/sda \
			mklabel msdos \
			mkpart primary ext4 1MiB $(($home_size + 1))MiB \
			mkpart primary linux-swap $(($home_size + 2))MiB $(($swap_size + $home_size + 2))MiB \
			mkpart primary ext4 $(($swap_size + $home_size + 3))MiB 100% \
			set 3 boot on
	fi
}

format_partion() {
	if [ -d /sys/firmware/efi ]; then	
		mkfs.fat -F32 /dev/sda1
	else 
		mkfs.ext4 /dev/sda1
	fi

	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2
	swapon /dev/sda2
}

mount_fs() {
	if [ -d /sys/firmware/efi ]; then
		mount /dev/sda3 /mnt
		mkdir /mnt/boot
		mount /dev/sda1 /mnt/boot
	else
		mount /dev/sda3 /mnt
		mkdir /mnt/home
		mount /dev/sda1 /mnt/home
	fi
}

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

unmount_disk() {
	if [ -d /sys/firmware/efi ]; then
		umount /mnt/boot
	else
		umount /mnt/home
	fi
	umount /mnt
}

setup() {
	echo "Disk partioning..."
	read -p "How much disk space do you want for swap? " SWAP_SIZE
	if [ -d /sys/firmware/efi ]; then
		partion 512 $SWAP_SIZE
	else
		partion 5000 $SWAP_SIZE
	echo "Finished."

	echo "Formating partions..."
	format_partion
	echo "Finished."

	echo "Mounting file system..."
	mount_fs
	echo "Finished."

	echo "Installing base and base devel..."
	install_base
	echo "Finished."

	echo "Generating file system table..."
	generate_fstab
	echo "Finished."

	curl $configure_sh_link > /mnt/$CONF_NAME
	change_root $CONF_NAME
}

main() {
	# configure file (execute during chroot)
	local CONF_NAME=configure.sh

	# change branch when downloading configure.sh from github
	local BRANCH=master
	local configure_sh_link=https://raw.githubusercontent.com/harrynguyen97/arch-installation/$BRANCH/configure.sh
	
	setup

	# Check if failed or not during chroot
	# if succeed, /mnt/$CONF_NAME would not exist.
	if [ -f /mnt/$CONF_NAME ]; then
		echo 'ERROR: Failed during chroot. Try again.'
		exit
	else
    	echo 'Unmounting filesystems'
    	unmount_disk
    	echo 'Finished. You should reboot system for applying changes.'
	fi
}

main
