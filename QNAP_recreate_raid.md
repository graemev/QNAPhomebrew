% QNAP\_recreate\_raid(8) Version 1.0 | Initial "QNAP\_recreate\_raid" Documentation

NAME
====

**QNAP\_recreate\_raid** — Convert an existing set of filesystem to raid (destructive)

SYNOPSIS
========

| **QNAP\_recreate\_raid** 
	\[**-v**|**--verbose**\] 
	\[**-p**|**--partition**\] _partition number_
	_number of drives_
	
| **QNAP\_recreate\_raid** \[**-h**|**--help**\]|\]**-V**|**--version**\]

DESCRIPTION
===========

Typically used after failures with QNAP\_create\_raid(8), it can be used a (a slightly more complex)
alternative. The common case would be:

	QNAP_recreate_raid -p9 4
	
Take partition 9 on the first 4 drives and form into a RAID array. This requires you know the
partition numbers.


Options
-------

-V, --version

:   Prints the current version number and exits.

-h, --help

:   Prints brief usage information.

-v, --verbose

:   Make output more verbose. 

-p _partition number_
: a simple number e.g. 9 , would take /dev/sda9, /dev/sdb9 .... to make a RAID array

_number of drives_
: e.g 4 would mean /dev/sda9, /dev/sdb9, /dev/sdc9 and /dev/sde9 [ 4 drives] would make up the RAID array.



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

**QNAP_create_raid(8)**
