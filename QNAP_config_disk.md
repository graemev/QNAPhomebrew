% QNAP\_config\_disks(1) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAP\_config\_disks** — Tries to keep HDD silent using internal firmware

SYNOPSIS
========

| **QNAP_config_disks** \[**-y**|**--sleep** ] 
	\[**-t**|**--timeout** seconds\] \[_not normally used can set a very low timeout to test_\]
	\[**-m**|**--mode** fast|medium|powersave|test\]
	\[**-p**|**--permanent** \] 
	\[**-v**|**--verbose**] ...list of drives 

| **QNAP_config_disks** \[**-h**|**--help**\]\[**-V**|**--version**]

DESCRIPTION
===========

This is an alternative to using QNAP_manage_disks(8). This would normally be the first mechanism
to try.

Uses hdparm(8) to set the power saving features of the disks. If -p is used the
settings are stored in /etc/hdparm.conf. NB the scripts which use /etc/hdparm.conf only
recognise format like /dev/sd? and /dev/hd?.

Read the comments in the script, the behaviour of different disks can be very different. Some spindown
almost as soon as it's possible, some hardy at all. Some disks spin up in response to checking something
innocuous like their temperature.



Options
-------

-m, --mode

:   One of fast, medium, powersave or test (default is medium)

Sets the style of powersaving for the disk depeding on whether saving power or
fast access is the primary objective. Beware that some disks would stop/start
every few seconds with the "wrong" settings which would quickly wear out the
drive. If you cannot get a suitable setting with this command, try
QNAP\_manage\_disks(8) instead.

testing is intended to be used as its name implies, the disk will spin down
very quickly, if this is set as the permanent mode then this behaviour may
damage the drive (due to frequent spin up/down).

-h, --help

:   Prints brief usage information.

-v, --verbose

:   Make output more verbose. 

-t, --timeout _seconds_ 
: Force a particular timeout. Useful in testing, dangerous to use with -p (as is testing mode)

-p, --permanent 
: Save settings so it persists across boot (be aware disk names are not fixed betwen boots)

-s, --sleep 
: Immediatly spin the disk down (useful in testing how active a disk is)


Getting the disk to spindonw is a primary goal of QNAPHomebrew. This is the
"easy" way to do it, however it does seem to work for many brands of drive.

If you cannot do it using this mechanism try QNAP_manage_disks(8).



FILES
=====

* /etc/hdparm.conf
: Stores the persistant settings for disks.


ENVIRONMENT
===========


BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========

**hdparm(8)**, **QNAP_manage_disks(8)**
