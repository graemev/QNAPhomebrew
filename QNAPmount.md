% QNAPmount(8) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAPmount** — Creates and exports (NFSv3) all the shareable filesystems

SYNOPSIS
========

| **QNAPmount**

DESCRIPTION
===========

This is a script you almost certainly need to edit. It defines where all the filesystems
are located, eg Multimedia,homes,Recordings,InternalAdmin,Download ... etc

With QTS, all the filesystem exist on one or more raid arrays. That is a possible use-case
here, but it not how it is initially setup. Looking into the script:

- REST1 defines the "share names" defined in /QNAP/mounts/rest1, which is where
  the filesystem with label=rest1 is mounted (we will just use the term "rest1" to refer to
  this from now on)
  
- REST2 defines the shares for rest2, etc

- RAID0 defines the "share names" for the raid array.

So, given the other QNAPhomebrew commands, and "normal" usage:

- RAID0 (if QNAP_create_raid(8) were used) would exist across all (4?) disks
- REST1 would be the "rest of the space" on the disk in TRAY1
- REST1 similar for TRAY2 ...

So, in the normal case, the trays would contain a disparate selection of disks
so data1, data2 would be the same size on each disk (so suitable for a RAID
array) whereas rest1, rest2 etc would be of very different sizes. Not all data
stored on the NAS warrant RAID; some data is critical but others like maybe
"media" are only on the NAS for convenient access, they also exist in other
locations.


Options
-------


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

 **QNAP_commision_disk.(8)**, **QNAPmount.service(5)**
