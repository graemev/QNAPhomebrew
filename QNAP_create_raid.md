% QNAP\_create\_raid(8) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAP\_create\_raid** — Convert an existing set of filesystem to raid (destructive)

SYNOPSIS
========

| **QNAP\_create\_raid** 
	\[**-v**|**--verbose**] ..._name_ _number_
	
| **QNAP\_create\_raid** \[**-h**|**--help**\]|\]**-V**|**--version**\]

DESCRIPTION
===========

Somewhat unusual (syntax) because it works across drives. The simplest way to
understand is to consider the default case name=data and number=4. This would
make a RAID array containing 4 components. The 4 components would be the 4
existing "data" partitions (data1, data2, data3 and data4 ... typically in
/dev/sda9, /dev/sdb9,/dev/sdc9 and /dev/sdd9.  Note it uses the label, which will
disappear during this process, so it cannot be rerun. If you need to recreate
the RAID use the command QNAP\_recreate\_raid(8) which slightly harder to use as
you need to know the actual partitions.

This command is the simple way to do it. It may just need "type the command".


Options
-------

-V, --version

:   Prints the current version number and exits.

-h, --help

:   Prints brief usage information.

-v, --verbose

:   Make output more verbose. 

- name an
- number

Define the "label" which will be repurposed to be part of the RAID array,
typically the 4 partitions currently labelled "dataX".

Be aware, once a RAID array exists over say 4 drives, IO to that filesystem may spin up all 4 drives.



FILES
=====


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

**QNAP\_recreate\_raid(8)**
