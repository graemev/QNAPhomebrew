% QNAP\_manage\_disks.service(5) Version 1.0 | Initial "QNAP\_manage\_disks.service" Documentation

NAME
====

**QNAP\_manage\_disks.service** — Runs QNAP\_manage\_disks as a systemd daemon

SYNOPSIS
========

| **QNAP\_manage\_disks.service**

| **/etc/systemd/system/QNAP\_manage\_disks.service**

| systemctl enable QNAP\_manage\_disks.service

| systemctl start QNAP\_manage\_disks.service

| systemctl stop  QNAP\_manage\_disks.service

| systemctl disable QNAP\_manage\_disks.service


DESCRIPTION
===========

See QNAP\_manage\_disks(8) . NB there are 2 versions of this command a C program
and a shell script. The C program is more feature rich and is the one with a man page.


FILES
=====

* /etc/systemd/system/QNAP\_manage\_disks.service


ENVIRONMENT
===========

Runs under systemd control


BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========

**hdparm(8)**, **QNAP_config_disk(8)**
