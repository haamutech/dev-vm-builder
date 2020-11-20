#!/bin/bash

set -e

if [ "$#" -lt 3 ]
then
    echo "Usage $0 [hostname] [root password] [output]"
    exit 1
fi

# Build a virtual disk image.
virt-builder -v -x "ubuntu-18.04" \
   --hostname "$1" \
   --smp "$(nproc)" \
   --install "apt-transport-https,ca-certificates,curl,gnupg-agent,software-properties-common,python-pip,python-dev,libguestfs-tools,samba,build-essential,git,htop" \
   --upload "setup.sh:/usr/sbin/setup-dev" \
   --upload "setup-data-disk.sh:/usr/sbin/setup-data-disk" \
   --run-command "setup-dev" \
   -o "${3}.raw" --format raw \
   --root-password "password:${2}" \
   --firstboot "firstboot.sh"

echo "Converting '${3}.raw' to '${3}.vhdx'. This may take a while."

# Convert raw virtual disk image to VHDX.
qemu-img convert -O vhdx "${3}.raw" "${3}.vhdx"
rm -f "${3}.raw"

echo "Virtual machine disk image was built to ${3}.vhdx"
