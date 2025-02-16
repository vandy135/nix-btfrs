#!/bin/bash

nix-shell -p cryptsetup

install_drive="/dev/nvme0n1"

# Zap the NVMe drive
sudo sgdisk --zap-all "$install_drive"

# Create a 1GB boot partition
sudo sgdisk -n 1:0:+1G -t 1:EF00 "$install_drive"

# Create a partition for the remaining space
sudo sgdisk -n 2:0:0 -t 2:BF00 "$install_drive"

# Make sure Boot is bootable
sudo parted $install_drive -- set 1 esp on

sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo fatlabel /dev/nvme0n1p1 BOOT

sudo cryptsetup --batch-mode -c aes-xts-plain64 --use-random luksFormat "/dev/nvme0n1p2"
sudo cryptsetup luksOpen "/dev/nvme0n1p2" luks

sudo mkfs.btrfs /dev/mapper/luks
#sudo mkdir /mnt
sudo mount /dev/mapper/luks /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/persist
sudo umount /mnt
sudo mount -o subvol=root,compress=lzo /dev/mapper/luks /mnt
sudo mkdir /mnt/{boot,home,persist}
sudo mount -o subvol=home,compress=lzo /dev/mapper/luks /mnt/home
sudo mount -o subvol=persist,compress=lzo /dev/mapper/luks /mnt/persist
sudo mount /dev/nvme0n1p1 /mnt/boot

