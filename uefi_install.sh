CONF_NAME=configure.sh
configure_sh_link=https://raw.githubusercontent.com/harrynguyen97/arch-installation/master/configure.sh

# $1: FAT32
# $2: swap
# $3: /
partion() {
	local fat_size=$1
	local swap_size=$2

	parted /dev/sda \
		mklabel gpt \
		mkpart ESP fat32 1MiB $(($fat_size + 1))MiB \
		set 1 boot on \
		mkpart primary linux-swap $(($fat_size + 2))MiB $(($swap_size + $fat_size + 2))MiB \
		mkpart primary ext4 $(($swap_size + $fat_size + 3))MiB 100%
}

format_partion() {
	mkfs.fat -F32 /dev/sda1
	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2
	swapon /dev/sda2
}

mount_fs() {
	mount /dev/sda3 /mnt
	mkdir /mnt/boot
	mount /dev/sda1 /mnt/boot
}

install_base() {
	echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
	pacstrap /mnt base base-devel
}

generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

change_root() {
	local execute_script=$1
	chmod +x /mnt/$execute_script
	arch-chroot /mnt ./$execute_script
}

unmount_disk() {
	umount /mnt/boot
	umount /mnt
}

setup() {
	echo "Disk partioning..."
	partion 512 2000
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

	if [ -f /mnt/$CONF_NAME ]; then
		echo 'ERROR: Failed during chroot. Try again.'
	else
    	echo 'Unmounting filesystems'
    	unmount_disk
    	echo 'Finished. You should reboot system for applying changes.'
	fi
}

setup