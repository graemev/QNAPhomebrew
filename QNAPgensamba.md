% QNAPgensamba(1) Version 1.0 | QNAPHomebrew admin

NAME
====

**QNAPgensamba** — regenerates /etc/samba/smb.conf

SYNOPSIS
========

| **QNAPgensamba** 

DESCRIPTION
===========

 **NB.** You can just edit your own smb.conf and not use this at all. 

This attempts to make the config more modular and also sets values suitable for QNAhomebrew.

The files in etc/QNAPsmb.d in this source tree are one per share, so you can
delete ones you don't want (or rename them so the extension is not .conf) the supplied
ones define shares similar to the ones QTS uses. See QNAPmount(8) to ensure these exist.

The file QNAPsmb.conf contains the base config. Things to note:

- This config is for a simple standalone server. If you have doze "Active
  Directory" (a bit like LDAP) domains, you probably ought to edit
  /etc/samba.smb.conf yourself.

- SMB1 is now considered dangerous and is disabled in many "doze" variants (so not enabled in config)

- On a doze client use get-smbserverconfiguration and check SMB1 support

- The Debian package "wsdd" (installed by QNAPinstalldepends(8)) makes the
  shares browsable on modern "doze" systems, older (like pre Windows95) systems
  use nmbd(8) this has many "sub optimal" behaviours and so it not enabled by
  default (use systemctl enable nmbd, if you really need it)






Options
-------

None


FILES
=====

* /etc/samba/smb.conf

:   config file for SAMBA (aka windoze shares)


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

**hdparm(8)**, **QNAP_config_disk(8)**
