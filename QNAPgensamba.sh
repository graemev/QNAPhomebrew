#! /bin/bash

# VERSION 1.0
#
# Creates /etc/samba/smb.conf. Based in info held here
#
#  QNAPsmb.conf + QNAPsmb.d/*
#
# Right now this is a simple concat of the files, but we could
# generate the individual files pretty easily from a template + some rules.

#
# We assume QNAPmount.sh will have been run/will run soon
# to create /share subdirectories


# Caller can override using environment variable
: ${BASE:=$PWD/etc}


cp /etc/samba/smb.conf  /etc/samba/smb.conf.old

cat ${BASE}/QNAPsmb.conf ${BASE}/QNAPsmb.d/*.conf > /etc/samba/smb.conf 

testparm 


cat <<EOF

On a windowbox (where you hope to use this) run get-smbserverconfiguration

Pay attemtion to SMB1 support

see: https://community.netgear.com/t5/Nighthawk-Wi-Fi-5-AC-Routers/Problem-with-NET-VIEW-W10-R7000-most-recent-firmware-including/m-p/1489207#M79997

EOF


