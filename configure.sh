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

# This script will configure the operating system (setting time zone, 
# setting language, changing password,...) during arch-chroot 

set_timezone() {
	local ZONE=$1

	# if localtime existed then delete it to make dynamic link
	if [ -f /etc/localtime ]; then 
		rm /etc/localtime
		echo "Removed existed /etc/localtime."
	fi

	ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime
	hwclock --systohc 
}

set_language() {
	local LANGUAGE=$1
	# Uncomment $LANGUAGE in locale.gen
	# #en_US.UTF-8 -> en_US.UTF-8
	sed -i "s/#$LANGUAGE/$LANGUAGE/g" /etc/locale.gen
	
	# generate locale
	locale-gen
	echo LANG=$LANGUAGE > /etc/locale.conf
	export LANG=$LANGUAGE
}

set_hostname() {
	read -p 'Enter host name: ' HOSTNAME
	echo $HOSTNAME > /etc/hostname
}

configure_network() {
	# install network
	pacman -S networkmanager && systemctl enable NetworkManager
}

set_user_password() {
	local USER=$1

	# status indicates if passwd succeed or not
	local status=1
	while [ $status -ne 0 ]
	do
		passwd $USER 
		status=$?
	done
}

install_necessary_packages() {
	local PACKAGES='vim bash-completion zsh zsh-completions sudo git'
	pacman -Sy $PACKAGES
}

install_bootloader() {
	pacman -S grub efibootmgr

	grub-install --target=x86_64-efi --efi-directory=/boot
	# if returned value of grub-install is not 0 then exit because of failure
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

# When installing arch linux on virtualbox, you just can boot installed 
# Arch when reboot but can not when shut down. This is the bug patch
virtualbox_bug_patch() {
	mkdir /boot/EFI/boot
	cp /boot/EFI/arch/grubx64.efi /boot/EFI/boot/bootx64.efi
}

create_user() {
	local status=1

	# Keep prompting user, until it succeeds
	while [ $status -ne 0 ]
	do
		read -p 'Username: ' USERNAME

		# Create user
		useradd -m -g users -G audio,video,network,wheel,storage \
		-s /bin/bash $USERNAME

		# indicates status of useradd
		status=$?
	done

		# Set password
		set_user_password $USERNAME

		echo "Setting up privilege..."

		# Comment out privilege in visudo
		# # %wheel ALL=(ALL) ALL -> %wheel ALL=(ALL) ALL
		# see 'sed in linux'
		local PRIVILEGE='%wheel ALL=(ALL) ALL'
		sed -i "s/# $PRIVILEGE/$PRIVILEGE/g" /etc/sudoers
		echo "Finished."
}

# Manual Installation
# - Open /etc/pacman.conf
# - Append 
#   >[arcolinux_repo_iso]
#   >SigLevel = Never
#   >Server = https://arcolinux.github.io/arcolinux_repo_iso/$arch
#   to the end of /etc/pacman.conf
# - Update system `pacman -Sy`
# - Install yaourt and package-query `pacman -S yaourt package-query`
# - After finish installation, comment out those appended lines above. We dont
#   want trash packages appear in our system.
#
# Below is the automatic installation 
install_yaourt() {
	# To avoid append the content multiple times

	# Find if [arcolinux_repo_iso] is in /etc/pacman.conf
	grep -Fxq "[arcolinux_repo_iso]" /etc/pacman.conf
	# if not found, then append the content below to /etc/pacman.conf
	if [ $? -ne 0 ]; then
		cat >> /etc/pacman.conf <<"EOF"
[arcolinux_repo_iso]
SigLevel = Never
Server = https://arcolinux.github.io/arcolinux_repo_iso/$arch
EOF
	fi

	pacman -Sy
	pacman -S yaourt package-query

	# To comment out the appended lines above

	# Find [arcolinux_repo_iso] again
	grep -Fxq "[arcolinux_repo_iso]" /etc/pacman.conf
	# If found, then comment out the appended lines above
	if [ $? -eq 0 ]; then
		# Get total number of lines in /etc/pacman.conf
		local NUMLINES=$(wc -l < /etc/pacman.conf)

		# This command means replace any empty character by # from 
		# line NUMLINES - 2 to the end of file.
		#
		# Also means comment out the last 3 lines of /etc/pacman.conf
		sed -i "$(($NUMLINES-2)),\$s/^/#/" /etc/pacman.conf
	fi
}

configure() {
	echo "Setting timezone..."
	set_timezone $TIMEZONE
	echo "Time zone is set to $TIMEZONE."

	echo "Setting language..."
	set_language $LANGUAGE
	echo "Language package is set to $LANGUAGE"

	echo "Setting host name..."
	set_hostname
	echo "Changed hostname successfully."

	echo "Configuring network..."
	configure_network
	echo "Finished."

	echo "Setting root password..."
	set_user_password root

	echo "Preparing to install bootloader..."
	install_bootloader

	echo "Installing necessary packages..."
	install_necessary_packages
	install_yaourt
	echo "Finished."
	
	# fix bug for virtualbox only
	echo "Fixing bug for virtualbox..."
	virtualbox_bug_patch
	echo "Finished."

	read -p 'Do you want to create user? (Y/N) ' option
	if [ "$option" == "Y" ]; then
		local option_user=Y
		while [ "$option_user" == "Y" ]
		do
			echo "Creating user..."
			create_user
			read -p "Do you want to create more user? (Y/N): " option_user
		done
	fi

	pacman -Syu
	echo "Full system upgraded."
}

main() {
	local TIMEZONE=Australia/Adelaide
	local LANGUAGE='en_US.UTF-8'
	
	configure

	# remove configure.sh in /mnt for indicates error in uefi_install.sh
	# if configure.sh still exists then there must be errors somewhere
	rm configure.sh
	
	exit
}

main