% QNAP_manage_disks(1) Version 1.0 | Initial "QNAP_manage_disks" Documentation

NAME
====

**QNAP_manage_disks** — Tries to keep HDD silent

SYNOPSIS
========

| **QNAP_manage_disks** \[**-T**|**--notemperature** ] \[_=list of disks_]
	\[**-N**|**--dry-run** ] 
	\[**-s**|**--sleep** seconds] \[_time to sleep between checks_]
	\[**-s**|**--warn** spindowns] \[_number of spindowns before warning_]
	\[**-s**|**--logevery** count] \[_number of wakeups before a summary_]
	\[**-v**|**--verbose**] ...list of drives
| **QNAP_manage_disks** \[**-h**|**--help**\[**-d**|**--debug**|**-V**|**--version**]

DESCRIPTION
===========

Monitors a set of disks (only HDD make sense) and spins the drive down if there
hase been no IO activity since the last time it checked. The defaults check once
an hour and generate a summary once every 24 hours.

This program is needed iff your HDD do not work well with hdparm(8) -B and -S,
you can managed some with hdparm(8) and some with this program.

Tested with a TS412. When this is tuned and qcontrol(1) config files set
appropriately it should be possible for an idle QNAP NAS to sit with all disks
stopped and the fan off/silent.

Normal usage of this command would be as a systemd daemon(7) (systemd.unit(5)) .


Options
-------

-V, --version

:   Prints the current version number and exits.

-h, --help

:   Prints brief usage information.

-v, --verbose

:   Make output more verbose. 

Warning, the non verbose output was designed for the case where one of the disks
being monitored also holds logs (like syslog) and would get woken up by the
output.

-d, --debug

:   Developer option. 

warning for verbose also apply.

-s, --sleep <seconds> default to 3600 (1 hour)

:   Sets how long this command sleeps between checks on the disks.

At each wakeup it checks on the disks, does any verbose about and spins down
disks that have seen no IO since it last awoke.


-l, --logevery <count> defaults to 24 (e.g. 1 day)

:   After waking up this many times, it prints a summary of it's activity (e.g. over the past day)
    

-w, --warn <count> defaults to  logevery-1

:   warn about too many spindown/spinup events

In a 24 sample run, there are 23 opportunities to spin a disk down. If on every
one of these, a given disk is spundown, that would mean it is getting spun up
every time.  This suggests the disk is actually quite active and maybe spining
it down (and up) e.g.  every hour is too much. So either check what is causing
the spin up (in case it is a mistake) or, if it turns out the disk is actually
used quite a lot consider NOT managing it.
	
You may expect a disk to stay busy during the day and totally idle at night, so
it would not attempt spindowns during the day and only need one or two in the
evening then it would stay idle overnight; in this case you might set a low
threshold say 3 or 4.

-T\[\<drive\>\*\], --notemperature\[=\<drive\>\*\]
:   Don't monitor temperature

By default it attempts to track the drive temperature. This may not be possible
because the driver **DRIVETEMP** is not avaiable or the drive does not support
it.  It also may not be **desirable** because some disks spin up when their
temperature is taken. This can be specified in two ways. First a naked -T or
--notemperature stops all attempts to monitor temperatures and does not even
attempt to load the driver. It can be more specific as in **-Tsda,sdd or
--notemp=tray1,/dev/sdc** in whch case certain drives have their temperature check
skipped (so their results are invvalid).


\<drives\>

This can be of the form \"sdb\"  or \"tray2\" or \"/dev/sdb\" . If a list of drives
is used after the command, they must be space seperated. When used on the -T option
they need to be comma seperated. It should be obvious why :-)




FILES
=====

* /sys/block/sd?/stat

:   IO stats for each disk.


* /sys/block/sd?/device/hwmon/hwmon?/temp1_input

:   Temperatures for each disk.

ENVIRONMENT
===========

**LD_LIBRARY_PATH**

:   This uses a private library libhdparm.so which needs to be in the load path.

BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========

**hdparm(8)**, **QNAP_config_disk(8)**
