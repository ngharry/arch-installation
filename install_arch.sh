parted /dev/sda \
	mklabel msdos \
	mkpart primary ext4 1MiB 20G \
	set 1 boot on \
	mkpart primary linux-swap 20G 22G \
	mkpart primary ext4 22G 100%
