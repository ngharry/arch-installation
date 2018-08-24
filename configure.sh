TIMEZONE=Australia/Adelaide
LANGUAGE='en_US.UTF-8'

set_timezone() {
	local ZONE=$1

	if [ -f /etc/localtime ]; then 
		rm /etc/localtime
		echo "Removed existed /etc/localtime."
	fi

	ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
	hwclock --systohc 
}

set_language() {
	local LANGUAGE=$1

	sed -i "s/#$LANGUAGE/$LANGUAGE/g" /etc/locale.gen
	locale-gen
	echo LANG=$LANGUAGE > /etc/locale.conf
	export LANG=$LANGUAGE
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

install_necessary_packages() {
	local PACKAGES='vim bash-completion zsh zsh-completions'
	pacman -Sy $PACKAGES
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

create_user() {
	read -p 'Username: ' USERNAME
	useradd -m -g users -G audio,video,network,wheel,storage -s /bin/bash $USERNAME

	passwd $USERNAME
	if [ $? -ne 0 ]; then
		echo "Failed to create user."
		exit
	fi

	echo "Setting up privilege..."
	local PRIVILEGE='%wheel ALL=(ALL) ALL'
	sed -i "s/# $PRIVILEGE/$PRIVILEGE/g" /etc/sudoers
	echo "Finished."
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

	echo "Installing necessary packages..."
	install_necessary_packages
	echo "Finished."
	
	# fix bug for virtualbox only
	echo "Fixing bug for virtualbox..."
	patch_for_virtualbox
	echo "Finished."

	local option=Y 
	while [ "$option" == "Y"]
	do
		echo "Creating user..."
		create_user
		read -p "Do you want to create more user? (Y/N): " option
	done


	pacman -Syu
	echo "Full system upgraded."
}

configure
rm configure.sh
exit