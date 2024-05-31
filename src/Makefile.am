bin_PROGRAMS=QNAP_manage_disks
man1_MANS=QNAP_manage_disks.8

QNAP_manage_disks_SOURCES=QNAP_manage_disks.c
QNAP_manage_disks_CPPFLAGS=-I$(top_srcdir) $(LIB_CPPFLAGS) -Wall
QNAP_manage_disks_LDADD=-Llib -lhdparm
QNAP_manage_disks_LDFLAGS=-Wl,-rpath=lib



.md.1:
.md.8:
	pandoc $< -s -t man -o $@


SUBDIRS=lib
dist_doc_DATA=README

#@GENERATE_CHANGELOG_RULES@
#CHANGELOG_START = 0.2.3^
#dist-hook: dist-ChangeLog
