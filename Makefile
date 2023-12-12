CFLAGS=-g

SBINS=count_goes count_flash_attempts  count_flash_actuals construct_dl_image\
	action_flash_kernel fake_flash_kernel dl_flash_kernel
BINS=QNAP_clone_alldisk QNAP_clone_disk QNAP_commision_disk QNAP_config_disk QNAP_create_raid\
	QNAP_recreate_raid QNAPgensamba QNAPmount QNAPinstalldepends QNAP_manage_disks

SERVICES=QNAP_manage_disks.service QNAPmount.service


#SUBDIRS := $(wildcard */.)
SUBDIRS := src




TARGETS= $(SBINS) $(BINS)
ISCRIPTS=choose-root
LIBS=dl_flash_functions

%.sh:

%: %.sh
#  recipe to execute (overriding built-in ...no write, so you don't edit the wrong version):
	rm -f $@
	cat $< >$@ 
	chmod 555 $@

ALL:	$(TARGETS) $(ISCRIPTS) $(SUBDIRS)
	etags *.[ch]

$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)



BIN=/usr/local/bin
SBIN=/usr/local/sbin
LIB=/usr/local/lib/QNAPhomebrew
INITRAM=/etc/initramfs-tools/scripts/local-top/
SYSTEMD=/etc/systemd/system

count_flash_attempts:	count_goes
	ln -s count_goes count_flash_attempts

count_flash_actuals:	count_goes
	ln -s count_goes count_flash_actuals


install:	ALL install_service
	install  	$(BINS)     $(BIN)
	install  	$(SBINS)    $(SBIN)
	install  	$(ISCRIPTS) $(INITRAM)
	install -D    	$(LIBS)	  $(LIB)
	rm -f $(SBIN)/flash-kernel && ln -s $(SBIN)/fake_flash_kernel $(SBIN)/flash-kernel

install_service:
	install	-m444	$(SERVICES) $(SYSTEMD)

clean:
	rm -f $(TARGETS)
