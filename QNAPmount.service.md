% QNAPmount.service(5) Version 1.0 | QNAPHomebrew service

NAME
====

**QNAPmount.service** — Runs QNAPmount under systemd once at boot time

SYNOPSIS
========

| **QNAPmount.service**

| **/etc/systemd/system/QNAPmount.service**

| systemctl enable QNAPmount.service

| systemctl start QNAPmount.service

| systemctl stop  QNAPmount.service

| systemctl disable QNAPmount.service


DESCRIPTION
===========

See QNAPmount(8) runs QNAPmount at boot time under systemd control.


FILES
=====

* /etc/systemd/system/QNAPmount.service


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

**hdparm(8)**, **QNAP\_config\_disk(8)**
