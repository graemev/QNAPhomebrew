TARGETS=QNAP_clone_alldisk QNAP_config_disk QNAP_clone_disk QNAP_commision_disk
ISCRIPTS=choose-root

ALL:	$(TARGETS)

BIN=/usr/local/bin
INITRAM=/etc/initramfs-tools/scripts/local-top/

install:	ALL
	cp -p $(TARGETS)  $(BIN)
	cp    $(ISCRIPTS) $(INITRAM)

clean:
	rm -f $(TARGETS)
