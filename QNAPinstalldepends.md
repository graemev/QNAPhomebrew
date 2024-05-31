% QNAP_installdepends(1) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAP_installdepends** — Installs packages needed by QNAPHomebrew (uninstall others)

SYNOPSIS
========

| **QNAP_installdepends** 

DESCRIPTION
===========

Check this script and amend as needed. Note it removes "java(1)" and "plymouth(8)" both
of which cause problems on the QNAP.

- Java simply coredumps (run java -verision)  which breaks some certificates.
- plymouth can't be used on a TS412 (since it lacks a display) but hugely
  increases initrd(4) size.


FILES
=====


ENVIRONMENT
===========

Run as user root.

BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========

**apt-get(8)**
