% QNAP\_clone\_alldisk(8) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAP\_clone\_alldisk** — Duplicates the existing system onto ALL disks.

SYNOPSIS
========

| **QNAP\_clone\_alldisk**

| **QNAP\_clone\_alldisk** \[**-h** | **--help**\] \[ **-V**|**--version**]

DESCRIPTION
===========

Clones the **CURRENT** configuration onto all the disks.

It does this by calling **QNAP\_clone\_disk -u -b _n_** on each disk this is NOT the current 
location of / (root)

This feels like a rarely used command, but quite the opposite it would be
appropriate to run this everytime anything on the system changed, such as
installing a new package. You might run it almost everyime you logon, but heed
the warnings below.

You may want to automate this process but consider where/how:

* Via crontab(1) or crontab(5) if you do make a global system change which makes
  the system unusable/unbootable, then the change may get replicated to all
  disk before the next reboot.
  
* via /etc/init.d or systemd(1) shortly after a boot. This might run after you make a change which broke
  networking but still allowed boot to complete, again the system may get replicated while not "working"
  
* Via a .profile (bash(1) ) for a given user (root/ admin / owner?) here the system is working to some
  extent at least
  
* At shutdown(8) again this is BEFORE a know good reboot, so most of the reservations above apply.


Options
-------

-V, --version

:   Prints the current version number and exits.

-h, --help

:   Prints brief usage information.

FILES
=====

* /etc/fstab

:   Needs to use the format LABEL=name_n_ to specify each filesystem

* /etc/initramfs-tools/conf.d/resume 

:   Changes to  RESUME=NONE

* /var/log

: This is not cloned, so it represents the log of the corresponding root.


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

**QNAP\_commission\_disk(8)**, **QNAP\_clone\_disk(8)**
