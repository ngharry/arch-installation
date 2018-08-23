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
	rm /etc/localtime
	ln -s /usr/share/zoneinfo/Australia/Adelaide /etc/localtime
	hwclock --systohc --utc
}

lang_setup() {
	sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
	locale-gen
	echo LANG=en_US.UTF-8 > /etc/locale.conf
	export LANG=en_US.UTF-8
}

hostname_setup() {
	echo harry-arch > /etc/hostname
}

password_setup() {
	passwd
}

systemctl_setup() {
	systemctl enable dhcpcd.service
}

grub_setup() {
	passwd && pacman -S grub os-prober 
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

	echo "Enter password..."
	password_setup

	echo "Finished."

	echo "Setting up grub..."
	grub_setup
	echo "Finished."


	fullsys_update
	echo "Full system updated."
	exit
}
if [ "$1" == "setup" ]
then
	setup
else 
	configure
fi

