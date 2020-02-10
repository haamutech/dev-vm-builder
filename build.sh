#!/bin/bash

set -e

if [ "$#" -lt 4 ]
then
    echo "Usage $0 [distribution image] [hostname] [root password] [output]"
    exit 1
fi

# Build a virtual disk image.
virt-builder -v -x $1 \
   --hostname $2 \
   --smp "$(nproc)" \
   --upload "setup.sh:/usr/sbin/setup-dev" \
   --upload "setup-data-disk.sh:/usr/sbin/setup-data-disk" \
   --run-command "setup-dev" \
   -o "${4}.raw" --format raw \
   --root-password "password:${3}" \
   --firstboot "firstboot.sh"

# Convert raw virtual disk image to VHDX.
qemu-img convert -O vhdx "${4}.raw" "${4}.vhdx"
rm -f "${4}.raw"

echo "Virtual machine disk image was built to ${4}.vhdx"
