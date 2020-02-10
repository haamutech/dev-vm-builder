#!/bin/bash

set -e

if [ "$#" -lt 1 ]
then
    echo "Usage $0 [data disk] ([initialize])"
    exit 1
fi

if [ "$2" == "true" ]
then
    # Make disk partitions.
    (echo "mklabel gpt" && echo "mkpart primary 2048s 100%") | parted $1

    # Make ext4 filesystem.
    mkfs.ext4 -m0 ${1}1
fi

# Create a data directory.
mkdir -p /mnt/data

# Make a backup of default fstab and restore original configuration.
mv -n /etc/fstab /etc/fstab.default
cp -f /etc/fstab.default /etc/fstab

# Write entry to fstab.
echo "${1}1 /mnt/data ext4 rw,relatime,data=ordered 0 0" >> /etc/fstab

# Mount everything from fstab.
mount -a

# Relocate home directory to mounted partition.
mkdir -p /mnt/data/home
rm -rf /home
ln -s /mnt/data/home /home

# Stop Docker because we are going to relocate its data directory.
service docker stop

# Relocate Docker directory to mounted partition.
mkdir -p /mnt/data/docker
rm -rf /var/lib/docker
ln -s /mnt/data/docker /var/lib/docker

# Start Docker again.
service docker start

# Create home for user.
mkhomedir_helper developer
