if [$(/sbin/sfdisk - d /dev/sda) == ""]
then 
	parted /dev/sda \
		mklabel msdos \
		mkpart primary ext4 1MiB 20G \
		set 1 boot on \
		mkpart primary linux-swap 20G 22G \
		mkpart primary ext4 22G 100%
fi
echo "Ola!"
# mkfs.ext4 /dev/sda1
# mkfs.ext4 /dev/sda3
# mkswap /dev/sda2
# swapon /dev/sda2

