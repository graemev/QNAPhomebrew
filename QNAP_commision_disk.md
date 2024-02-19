% QNAP_commission_disk(1) Version 1.0 | Initial "QNAP_commission_disk" Documentation

NAME
====

**QNAP_commission_disk** — Tries to keep HDD silent

SYNOPSIS
========

 **QNAP_commission_disk** \[**-b**|**--bootorder** _n_ \] 
	\[**-v**|**--verbose**]
	\[**-c**|**--check**] ..._drive_

| **QNAP_commission_disk** \[**-h**|**--help**\]

DESCRIPTION
===========

Probably one of the first commands run in setting up QNAPHombrew.

It partitions the given disk to make it suitable for the QNAPHomebrew model**.

Options
-------

-h, --help

   Prints brief usage information.

-v, --verbose

   Make output more verbose. 

-b, --bootorder

   Determines the "preference" for this disk at boot (see model**)

-c, --check passes  
	The check flag to mkfs (can be specified twice, see mkfs(8) man page

\<dev\>

	The device being reformatted. Can be of the form /dev/sdb or tray3 etc.

This is relatively destructive command. You are, in effect, handing the whole
disk over to the QNAPHomebrew "world". To reduce the risk of accidental trashing
an in-use disk it first checks the disk is "empty" . To make it empty you should
simply add a GPT partition table (e.g. with gparted in another machine, but any
method is acceptable) . There is no actual need for GPT but no other
partitioning systems have not been tested.

You should use unique numbers for the bootorder, this is not checked or enforced
but the choice of boot disk in that situation is undefined.

This command makes the filesystems:

- boot
- root
- var
- swap
- tmp
- home
- data
- rest

With the appropriate labels (e.g. label=home3) as required by the model**. You
may well want to customise this script to choose values suitable for the odd
disks you have. The partition with the label "dataX" will be of fixed size and
exist in partition 9 (so /dev/sda9, /dev/sdc9 etc ..to be clear the filesystem on
/dev/sdc9 may have the label data3 [3rd disk]) , so make sure that size fits on
all the disks you plan to use it on (need not be all disks). Partition 9 is
unusual in that it can be used as "yet another filesystem" (as-is) or replaced
with a single RAID array "/dev/md0" ( see: QNAP\_create\_raid(8) and
QNAP\_recreate\_raid(8)).

In the reference system. There were 4 HDD and a single (new) external SSD.

- TRAY1 => sda => SAMSUNG HD103UJ      (1TB)
- TRAY2 => sdb => SAMSUNG HD154UI      (1.5TB) 
- TRAY3 => sdc => HGST HDN724040ALE640 (4TB)
- TRAY4 => sdd => SAMSUNG HD154UI      (1.5TB)
- TRAY5 => sde => Kingston SSD         (0.5TB)

These would have been commissioned as:

	QNAP_commission_disk -b1 tray1 
	QNAP_commission_disk -b2 tray2
	QNAP_commission_disk -b3 tray3
	QNAP_commission_disk -b4 tray4
	QNAP_commission_disk -b5 /dev/sde
	

This neat layout is very nice and helpfully it's actually what seems to happen
when the QNAP is booted with all disks in place. However, be aware, if disks are
added or removed post boot the numbering will differ. Also you MAY choose a
different layout. However ease-of-use features like "TrayX" will assume this
setup and examples in manuals also use it.


**MODEL
=====

To explain the model, it is easiest to consider a concrete example (the system
this was developed on). This is an "old" TS412 , which is an ARM based system
with 4 "trays" holding disks + 2 eSATA sockets. The Trays hold an odd assortment
of disks which were "retired" from another (QNAP) NAS for various reasons (too
small, too hot, reporting SMART errors).

The use case is that this NAS holds infrequently accessed data" maybe backups or
saved scans of documents or Photos. This system would normally sit with all the
disks stopped and the Fan switched off. On my system this settles at around 37C
and is, of course, silent.

The system should be able to boot with ANY SINGLE DISK remaining, so 3 of the 4
disks could fail and it would still boot. In the reference system I added a 5th
disk, a small SSD plugged into the first eSATA port, this may sometimes be
called Tray5.

The key to the resilience is an initrd(4) script called 'choose_root' this gets
installed (by the Makefile) in /etc/initramfs-tools/scripts/local-top/. It looks
for filesystems with labels like root1, root5 etc (single digit) and when it has
checked them all it chooses the one with the highest number and that becomes the
root filesystem. This in turn mounts label=homeX on /home etc, this is defined
by your /etc/ftab. For example:


	 LABEL=root5 /                   ext4    errors=remount-ro   0       1
	 LABEL=boot5 /boot               ext4    defaults            0       2
	 LABEL=home5 /home               ext4    defaults            0       2
	 LABEL=tmp5  /tmp                ext4    defaults            0       2
	 LABEL=var5  /var                ext4    defaults            0       2
	 LABEL=swap5 none                swap    sw                  0       0


Note, unless you use QNAP\_create\_raid(8) and/or QNAP\_recreate\_raid(8) there will
be no RAID in this setup, so no data resilience.

Then next feature of this model is that the first few filesystems (root, boot,
home,tmp, var) are all "almost" identical. This is achieved by use of 
QNAP\_clone\_disk(8) QNAP\_clone\_alldisk(8). This has a side-effect that files
stored in /home will have many identical copies.

So the combination of choose_root script(8) QNAP_commission_disk(8) and
QNAP_clone_disk(8) provide the "secret sauce" that allows the system to come up
with only one working disk.



FILES
=====

* /etc/fstab

:   Needs custom setup using label= style syntax.


THE BOOTSTRAP ISSUE
===================

The "elephant in the room" is how do you get started. Well there are a number
of strategies. The one I used was:

1. Install Debian (bookworm)
   - I started with stretch and upgraded
   - see QNAPinstalldepends(8), to shrink initrd(4)
   - read up on SABOTEUR, Mouiche and M11 layouts
   - Read up on the "flash features"*** of QNAP Homebrew.
2. Install 'choose_root'
3. Use QNAP\_commission\_disk(8) to setup a new disk.
4. Use QNAP\_clone\_disk(8) to clone the existing system onto the new disk
5. Reboot, and check you come up with the new disk as / (root)
6. Commission mores disks and clone to them all.


***My first TS412 Motherboard failed while reflashing, so I now boot via BOOTP
and avoid reflashing the system.

BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========

**hdparm(8)**, **QNAP_config_disk(8)**, **sfdisk(8)**, **fdisk(8)**, **cfdisk(8)**, **parted(8)**
