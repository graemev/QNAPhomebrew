% QNAP\_clone\_disk(8) Version 1.0 | Initial "QNAP\_clone\_disk" Documentation

NAME
====

**QNAP\_clone\_disk** — Duplicates the existing system.

SYNOPSIS
========

| **QNAP\_clone\_disk**
	\[**-q**|**--quiet** ] 
	\[**-v**|**--verbose**] 
	\[**-b**|**--bootorder** _n_ \] 

| **QNAP\_clone\_disk** \[**-h** | **--help**\] \[ **-V**|**--version**]

DESCRIPTION
===========

Clones the **CURRENT** configuration to the one specified by **--bootorder**. 

So -b 2 would write the current configuration onto whichever disk held root2.

So if, for example, we had all 5 "trays" running with root1....to root5 , the
system would choose "root5" as the root filesystem. This would in turn mount:
home5, var5 etc. Then **-b** here would cause root5 to be copied to root2, home5 to
home2 etc.

This command uses bootorder (as used in QNAP\_commission\_disk(8)) rather than
explicitly specifying the disk, because this command might well be used to
deliberately overwrite a configuration. If for example root5 was bad (eg a bad
install) which might even prevent a successful boot, you could "pop the disk"
(unplug the eSATA) the system would then boot using root4, then you could plug
in the disk with root5 and say:

	QNAP_clone_disk -b5 
	
then root4 would overwrite root5 (hopefully "fixing" it).

It's an oversimplification to say it "copies" a filesystem, certain changes are
required, so the process (based on labels created by QNAP\_commission\_disk(8)) is:


  * boot Cloned
  * root Cloned  (/etc/fstab, /etc/initramfs-tools/conf.d/resume are updated) 
  * var  Partial Clone (/var/log is left unchanged)
  * SWAP No Action
  * tmp  No Action
  * home Clones
  * data No Action
  * rest No Action

All filesystems have a file called @CLONED created in their root, detailing the clone event. 

If you keep a few files in /home these will get copied of other disks. Most of the real data lives in
rest and data (either as a filesystem or via /dev/md0)

 **You probably won't use this command much, instead use QNAP\_clone\_alldisk(8).**

You may want to
automate this process but consider where/how:

* Via crontab(1) or crontab(5) if you do say a global system change which make
  the system unusable/unbootable, then the change may get replicated to all
  disk before the next reboot.
  
* via /etc/init.d or systemd(1) shortly after a boot. This might run after you make a change which broke
  networking but still allowed boot to complete, again the system may get replicated while not "working"
  
* Via a .profile (bash(1) ) for a given user (root/ admin / owner?) here the system is working to some
  extent at least
  
* at shutdown(8) again this is BEFORE a know good reboot, so most of the reservations above apply.




Options
-------

-V, --version

:   Prints the current version number and exits.

-q, --quiet

:   Useful in scripts, does not ask any questions and generates minimum output.

-h, --help

:   Prints brief usage information.

-v, --verbose

:   Make output more verbose. 

-b, --bootorder _n_

:   The **target** of the clone, copy goes from here to target. Based on the disk which holds label=root_n_


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

**QNAP\_commission\_disk(8)**, **QNAP\_clone\_alldisk(8)**
