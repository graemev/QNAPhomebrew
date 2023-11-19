TARGETS=QNAP_clone_alldisk QNAP_clone_disk QNAP_commision_disk QNAP_config_disk QNAP_create_raid\
	QNAP_recreate_raid QNAPgensamba QNAPmount QNAPinstalldepends
ISCRIPTS=choose-root

ALL:	$(TARGETS) $(ISCRIPTS)

BIN=/usr/local/bin
INITRAM=/etc/initramfs-tools/scripts/local-top/

install:	ALL
	cp -p $(TARGETS)  $(BIN)
	cp    $(ISCRIPTS) $(INITRAM)

clean:
	rm -f $(TARGETS)
