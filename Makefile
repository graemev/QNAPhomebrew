CFLAGS=-g

SBINS=count_goes count_flash_attempts  count_flash_actuals construct_dl_image\
	action_flash_kernel fake_flash_kernel dl_flash_kernel
BINS=QNAP_clone_alldisk QNAP_clone_disk QNAP_commision_disk QNAP_config_disk QNAP_create_raid\
	QNAP_recreate_raid QNAPgensamba QNAPmount QNAPinstalldepends

MAN1=QNAPinstalldepends.1 
MAN5=QNAP_manage_disks.service.5 QNAPmount.service.5
MAN7=QNAPflash.7
MAN8=QNAP_clone_alldisk.8 QNAP_clone_disk.8 QNAP_commision_disk.8 QNAP_config_disk.8 QNAP_create_raid.8 QNAP_recreate_raid.8 QNAPgensamba.8  QNAPmount.8 

MANS=$(MAN1) $(MAN5) $(MAN7) $(MAN8)


# This works but there us a better C program version (same name)
NOTBUILT=QNAP_manage_disks

SERVICES=QNAP_manage_disks.service QNAPmount.service


#SUBDIRS := $(wildcard */.)
SUBDIRS := src




TARGETS= $(SBINS) $(BINS) $(MANS)
ISCRIPTS=choose-root
LIBS=dl_flash_functions

%.sh:

%: %.sh
#  recipe to execute (overriding built-in ...no write, so you don't edit the wrong version):
	rm -f $@
	cat $< >$@ 
	chmod 555 $@

ALL:	$(TARGETS) $(ISCRIPTS) $(SUBDIRS)
#	etags *.[ch]

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)

BIN=/usr/local/bin
SBIN=/usr/local/sbin
LIB=/usr/local/lib/QNAPhomebrew
INITRAM=/etc/initramfs-tools/scripts/local-top/
SYSTEMD=/etc/systemd/system

MAN1DIR=/usr/local/man/man1
MAN5DIR=/usr/local/man/man5
MAN7DIR=/usr/local/man/man7
MAN8DIR=/usr/local/man/man8



count_flash_attempts:	count_goes
	ln -s count_goes count_flash_attempts

count_flash_actuals:	count_goes
	ln -s count_goes count_flash_actuals


install:	ALL install_service install_man $(SUBDIRS)
	install  	$(BINS)     $(BIN)
	install  	$(SBINS)    $(SBIN)
	install  	$(ISCRIPTS) $(INITRAM)
	install -D    	$(LIBS)	    $(LIB)
	rm -f $(SBIN)/flash-kernel && ln -s $(SBIN)/fake_flash_kernel $(SBIN)/flash-kernel
#	for subdir in $(SUBDIRS); do \
#	  echo "GPV Making $$target in $$subdir"; \
#	  cd $$subdir && $(MAKE) $@; \
#	done
#	Dubious this works for multiple subdir, may need the above text
	$(MAKE) -C $(SUBDIRS) $@

install_service:
	install	-m444	$(SERVICES) $(SYSTEMD)

install_man:
	install	-D -m644 -t $(MAN1DIR)			$(MAN1)	   
	install	-D -m644 -t $(MAN5DIR)			$(MAN5)	 
	install	-D -m644 -t $(MAN7DIR)			$(MAN7)	    
	install	-D -m644 -t $(MAN8DIR)			$(MAN8)	 


clean:
	rm -f $(TARGETS)

%.1: %.md
	pandoc $< -s -t man -o $@

%.5: %.md
	pandoc $< -s -t man -o $@

%.7: %.md
	pandoc $< -s -t man -o $@

%.8: %.md
	pandoc $< -s -t man -o $@
