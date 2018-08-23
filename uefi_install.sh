partion() {
	parted /dev/sda \
		mklabel gpt \
		mkpart ESP fat32 1M 513M \
		set 1 boot on \
		mkpart primary linux-swap 513M 2561M \
		mkpart primary ext4 2561M 100%
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
	pacstrap /mnt base base-devel
}

generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

change_root() {
	arch-chroot /mnt /bin/bash
}

setup() {
	echo "Disk partioning..."
	partion
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

	change_root
	echo "Changed root for moving to actual installation."
}

if [ "$1" == "setup"]
then 
	setup
else
	echo "Configuration has not been written."
fi