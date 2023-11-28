SBINS=count_goes count_flash_attempts  count_flash_actuals construct_dl_image action_flash_kernel fake_flash_kernel dl_flash_kernel
BINS=QNAP_clone_alldisk QNAP_clone_disk QNAP_commision_disk QNAP_config_disk QNAP_create_raid\
	QNAP_recreate_raid QNAPgensamba QNAPmount QNAPinstalldepends 



TARGETS= $(SBINS) $(BINS)
ISCRIPTS=choose-root
LIBS=dl_flash_functions

ALL:	$(TARGETS) $(ISCRIPTS)

BIN=/usr/local/bin
SBIN=/usr/local/sbin
LIB=/usr/local/lib/QNAPhomebrew
INITRAM=/etc/initramfs-tools/scripts/local-top/

count_flash_attempts:	count_goes
	ln -s count_goes count_flash_attempts

count_flash_actuals:	count_goes
	ln -s count_goes count_flash_actuals


install:	ALL
	install  	$(BINS)     $(BIN)
	install  	$(SBINS)    $(SBIN)
	install  	$(ISCRIPTS) $(INITRAM)
	install -D    	$(LIBS)	  $(LIB)
	rm -f $(SBIN)/flash-kernel && ln -s $(SBIN)/fake_flash_kernel $(SBIN)/flash-kernel

clean:
	rm -f $(TARGETS)
