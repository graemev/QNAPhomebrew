bin_PROGRAMS=myhdparm QNAP_manage_disks

myhdparm_SOURCES=myhdparm.c
myhdparm_CPPFLAGS=-I$(top_srcdir) $(LIB_CPPFLAGS)
myhdparm_LDADD=-Llib -lhdparm
myhdparm_LDFLAGS=-Wl,-rpath=lib

QNAP_manage_disks_SOURCES=QNAP_manage_disks.c
QNAP_manage_disks_CPPFLAGS=-I$(top_srcdir) $(LIB_CPPFLAGS)
QNAP_manage_disks_LDADD=-Llib -lhdparm
QNAP_manage_disks_LDFLAGS=-Wl,-rpath=lib

SUBDIRS=lib
dist_doc_DATA=README
