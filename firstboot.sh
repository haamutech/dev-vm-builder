#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Set UTC time.
timedatectl set-timezone UTC

# Use resolv.conf with real nameservers instead of systemd-resolve stub.
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Make a backup of default netplan configuration.
mv -n /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.default

# Overwrite netplan to configure two network interfaces, eth0 for DHCP and eth1 for internal static IP.
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      addresses: [172.18.0.2/24]
" > /etc/netplan/01-netcfg.yaml

# Apply network configuration.
netplan apply

# Regenerate SSH server keys.
dpkg-reconfigure openssh-server

internal_ip=""

# Try to retrieve internal IP address every second until it succeeds.
while [ -z "$internal_ip" ]
do
    internal_ip=$(ip -4 -o addr show eth1 | awk '/inet/ {print $4}' | cut -d/ -f1)
    sleep 1
done

# Make SSH to listen only internal network eth1.
echo "ListenAddress           $internal_ip" >> /etc/ssh/sshd_config

# Restart ssh, samba and docker.
service ssh restart
service smbd restart
service docker restart

# Add normal unix user.
useradd -s /bin/bash developer

# Add user to docker group to use docker.
addgroup developer docker

# Unlock user and remove the password.
passwd -d developer

# Add samba user with empty password.
(echo '' && echo '') | smbpasswd -a developer

# Allow user to use sudo without password.
echo "developer     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
