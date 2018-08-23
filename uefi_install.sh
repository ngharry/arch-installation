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
	chmod +x /mnt/$1
	arch-chroot /mnt ./$1
}

unmount_disk() {
	umount /mnt/boot
	umount /mnt
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

	cat > /mnt/configure.sh <<"EOF"
TIMEZONE=Australia/Adelaide
LANGUAGE=en_US.UTF-8

set_timezone() {
	if [ -f /etc/localtime ]
	then 
		rm /etc/localtime
		echo "Removed existed /etc/localtime."
	fi

	ln -sf /usr/share/zoneinfo/$1 /etc/localtime
	hwclock --systohc 
}

set_language() {
	sed -i 's/#$1/$1/g' /etc/locale.gen
	locale-gen
	echo LANG=$1 > /etc/locale.conf
	export LANG=$1
}

set_hostname() {
	read -p 'Enter host name: ' HOSTNAME
	echo $HOSTNAME > /etc/hostname
}

configure_network() {
	pacman -S networkmanager && systemctl enable NetworkManager
}

set_root_password() {
	passwd

	if [ $? -ne 0 ]; then
		exit
	fi
}

install_bootloader() {
	pacman -S grub efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot
	
	grub-mkconfig -o /boot/grub/grub.cfg
}

patch_for_virtualbox() {
	mkdir /boot/EFI/boot
	cp /boot/EFI/arch/grubx64.efi /boot/EFI/boot/bootx64.efi
}

configure() {
	echo "Setting timezone..."
	set_timezone $TIMEZONE
	echo "Finished."

	echo "Setting language..."
	set_language $LANGUAGE
	echo "Finished."

	echo "Setting host name..."
	set_hostname
	echo "Finished."

	echo "Configuring network..."
	configure_network
	echo "Finished."

	echo "Setting root password..."
	set_root_password
	echo "Finished."

	echo "Preparing to install bootloader..."
	install_bootloader
	echo "Finished."

	# fix bug for virtualbox only
	echo "Fixing bug for virtualbox..."
	patch_for_virtualbox
	echo "Finished." 

	pacman -Syu
	echo "Full system upgraded."
}

configure
exit
EOF
	change_root configure.sh

	echo "Unmounting disk..."
	unmount_disk
	echo "Finished."

	# read -p 'Do you want to reboot? (Y/N): ' option
	# if [ "$option" == "Y" ]; then
	# 	reboot
	# elif [ "$option" == "N" ]; then
	# 	echo "Finished installation. You can reboot later."
	# else 
	# 	echo "Invalid option."
	# fi
}

setup

