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

# Create directories to data mount.
mkdir -p /mnt/data/home
mkdir -p /mnt/data/var/lib/docker

# Make a backup of default fstab and restore original configuration.
mv -n /etc/fstab /etc/fstab.default
cp -f /etc/fstab.default /etc/fstab

# Write entry to fstab.
echo "${1}1 /mnt/data ext4 rw,relatime,data=ordered 0 0" >> /etc/fstab

# Add bind mounts to fstab for /home and Docker data.
echo "/mnt/data/home /home none bind" >> /etc/fstab
echo "/mnt/data/var/lib/docker /var/lib/docker none bind" >> /etc/fstab

# Stop Docker because we are going to relocate its data directory.
service docker stop

# Ensure that mounts points are available.
mkdir -p /home
mkdir -p /var/lib/docker

# Wipe out all existing data.
rm -rf /home/*
rm -rf /var/lib/docker/*

# Mount everything from fstab.
mount -a

# Start Docker again.
service docker start

# Create home for user.
mkhomedir_helper developer
