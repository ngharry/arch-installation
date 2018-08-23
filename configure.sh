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
	if [ $? -ne 0 ]; then
		echo "grub-install failed."
		exit
	fi

	grub-mkconfig -o /boot/grub/grub.cfg
	if [ $? -ne 0 ]; then
		echo "grub-mkconfig failed."
		exit
	fi
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
	echo "Changed hostname successfully."

	echo "Configuring network..."
	configure_network
	echo "Finished."

	echo "Setting root password..."
	set_root_password

	echo "Preparing to install bootloader..."
	install_bootloader

	# fix bug for virtualbox only
	echo "Fixing bug for virtualbox..."
	patch_for_virtualbox
	echo "Finished." 

	pacman -Syu
	echo "Full system upgraded."
}

configure
rm configure.sh
exit