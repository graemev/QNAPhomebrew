#! /bin/bash


#
# Installs pages used by or useful with QNAPhombrew
#
apt-get -u update

apt-get -y install nfs-kernel-server
apt-get -y install nfs-common

apt-get -y install wsdd
apt-get -y install samba
apt-get -y install smbclient

apt-get -y install rsync
apt-get -y install minidlna
apt-get -y install openssh-server

apt-get -y install lua5.1
apt-get -y install liblua5.1-0

apt-get -y install fdisk
apt-get -y install mdadm
apt-get -y install mtd-utils
apt-get -y install debian-keyring
apt-get -y install lvm2
apt-get -y install curl
apt-get -y install gnupg2
apt-get -y install cpufrequtils
apt-get -y install usbutils
apt-get -y install discover
apt-get -y install sudo

apt-get -y install smartmontools


apt-get -y install x11-apps
apt-get -y install xauth

apt-get install unattended-upgrades apt-listchanges

apt-get -y remove plymouth
apt-get -y remove openjdk-17-jre-headless

apt-get -y autoremove
apt-get -y pandoc
