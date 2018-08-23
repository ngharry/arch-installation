# echo "Partioning disk..."
# parted /dev/sda \
# 	mklabel msdos \
# 	mkpart primary ext4 1MiB 20G \
# 	set 1 boot on \
# 	mkpart primary linux-swap 20G 22G \
# 	mkpart primary ext4 22G 100%
# echo "Finished."

# echo "Making file system..."	
# mkfs.ext4 /dev/sda1
# mkfs.ext4 /dev/sda3
# mkswap /dev/sda2
# swapon /dev/sda2
# echo "Finished."

# echo "Mounting file system..."
# mount /dev/sda1 /mnt
# mkdir /mnt/home
# mount /dev/sda3 /mnt/home
# echo "Finished."

# pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
rm /etc/localtime
ln -s /usr/share/zoneinfo/Australia/Adelaide /etc/localtime
hwclock --systohc --utc