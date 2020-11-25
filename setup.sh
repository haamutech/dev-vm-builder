#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Update the system.
apt-get -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" -y upgrade

# Add Docker repository.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get -y update

# Install Docker.
apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io

# Make a backup of default smb.conf.
mv /etc/samba/smb.conf /etc/samba/smb.conf.default

# Overwrite smb.conf to bind only internal network eth1 and lo.
echo "# Created by setup.sh
[global]
        bind interfaces only = Yes
        dns proxy = No
        interfaces = lo eth1
        log file = /var/log/samba/log.%m
        map to guest = Bad User
        max log size = 50
        server role = standalone server
        server string = Development Server
        workgroup = MYGROUP
        idmap config * : backend = tdb
[homes]
        browseable = No
        comment = Home Directories
        read only = No
[tmp]
        comment = Temporary file space
        guest ok = Yes
        path = /tmp
        read only = No" > /etc/samba/smb.conf

# Make a backup of default sshd_config.
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.default

# Overwrite sshd_config to allow authentication only by SSH key.
echo "# Created by setup.sh
AuthorizedKeysFile      .ssh/authorized_keys
PasswordAuthentication  no
Subsystem               sftp    /usr/lib/ssh/sftp-server" > /etc/ssh/sshd_config

# Setup locales.
locale-gen en_US.UTF-8
echo "LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8" >> /etc/environment
