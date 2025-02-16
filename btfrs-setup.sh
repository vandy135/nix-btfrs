!/bin/bash

#validate drive
#install_drive="/dev/nvme0n1"

# Zap the NVMe drive
sgdisk --zap-all "$install_drive"
# Create a 1GB boot partition
sgdisk -n 1:0:+1G -t 1:EF00 "$install_drive"
# Create a partition for the remaining space
sgdisk -n 2:0:0 -t 2:BF00 "$install_drive"
# Make sure Boot is bootable
parted $install_drive -- set 1 esp on

mkfs.fat -F 32 /dev/nvme0n1p1
fatlabel /dev/nvme0n1p1 BOOT

cryptsetup --batch-mode -c aes-xts-plain64 --use-random luksFormat "/dev/nvme0n1p2"
cryptsetup luksOpen "/dev/nvme0n1p2" luks

mkfs.btrfs /dev/mapper/luks
# mkdir /mnt # do not need with install media
mount /dev/mapper/luks /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/persist
umount /mnt
mount -o subvol=root,compress=lzo /dev/mapper/luks /mnt
mkdir /mnt/{boot,home,persist}
mount -o subvol=home,compress=lzo /dev/mapper/luks /mnt/home
mount -o subvol=persist,compress=lzo /dev/mapper/luks /mnt/persist
mount /dev/nvme0n1p1 /mnt/boot

nixos-generate-config --root /mnt
nixos-install
