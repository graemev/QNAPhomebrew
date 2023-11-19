EXTRAS=count_goes count_flash_attempts  count_flash_actuals construct_dl_image action_flash_kernel fake_flash_kernel

TARGETS=QNAP_clone_alldisk QNAP_clone_disk QNAP_commision_disk QNAP_config_disk QNAP_create_raid\
	QNAP_recreate_raid QNAPgensamba QNAPmount QNAPinstalldepends  $(EXTRAS)

ISCRIPTS=choose-root

ALL:	$(TARGETS) $(ISCRIPTS)

BIN=/usr/local/bin
INITRAM=/etc/initramfs-tools/scripts/local-top/

count_flash_attempts:	count_goes
	ln -s count_goes count_flash_attempts

count_flash_actuals:	count_goes
	ln -s count_goes count_flash_actuals


install:	ALL
	cp -p $(TARGETS)  $(BIN)
	cp    $(ISCRIPTS) $(INITRAM)

clean:
	rm -f $(TARGETS)
