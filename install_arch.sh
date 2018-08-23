TIMEZONE='Australia/Adelaide'
LANGUAGE=en_US.UTF-8
PASSWORD='*'

setup() {
	echo "Partioning..."
	partion
	echo "Finished."

	echo "Formating..."
	format_fs
	echo "Finished."

	echo "Mounting..."
	mount_disk
	echo "Finished"
	
	pacstrap /mnt base base-devel
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt /bin/bash
}

partion() {
	parted /dev/sda \
    		mklabel msdos \
        	mkpart primary ext4 1MiB 20G \
        	set 1 boot on \
        	mkpart primary linux-swap 20G 22G \
			mkpart primary ext4 22G 100%
}

format_fs() {
	mkfs.ext4 /dev/sda1
	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2
	swapon /dev/sda2
}

mount_disk() {
	mount /dev/sda1 /mnt
	mkdir /mnt/home
	mount /dev/sda3 /mnt/home
}

time_setup() {
	if [ -f /etc/localtime ]
	then 
		echo "Remove existed file."
		rm /etc/localtime
	fi

	ln -sT "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
	hwclock --systohc --utc
}

lang_setup() {
	sed -i 's/#$LANGUAGE/$LANGUAGE/g' /etc/locale.gen
	locale-gen
	echo LANG=$LANGUAGE > /etc/locale.conf
	export LANG=$LANGUAGE
}

hostname_setup() {
	read -p 'Hostname: ' HOSTNAME
	echo $HOSTNAME > /etc/hostname
}

password_setup() {
	local PASSWORD=$1
	echo -en "$PASSWORD\n$PASSWORD" | passwd
}

systemctl_setup() {
	systemctl enable dhcpcd.service
}

grub_setup() {
	pacman -S grub os-prober 
	grub-install /dev/sda
	grub-mkconfig -o /boot/grub/grub.cfg
}

fullsys_update() {
	pacman -Syu
}

configure() {
	echo "Setting time..."
	time_setup
	echo "Finished."

	echo "Setting language..."
	lang_setup
	echo "Finished"

	echo "Setting host name..."
	hostname_setup
	echo "Finished."

	echo "Enabling dhcpcd..."
	systemctl_setup
	echo "Finished."

	read -sp 'Enter root password: ' PASSWORD
	password_setup PASSWORD
	echo "Finished."

	echo "Setting up grub..."
	grub_setup
	echo "Finished."


	fullsys_update
	echo "Full system updated." \
	
	exit
	echo "Exited." \

	reboot
}
if [ "$1" == "setup" ]
then
	setup
else 
	configure
fi

