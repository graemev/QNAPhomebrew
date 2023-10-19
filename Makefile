TARGETS=QNAP_clone_alldisk QNAP_config_disk QNAP_clone_disk QNAP_commision_disk

ALL:	$(TARGETS)

install:	ALL
	cp -p ${TARGETS} $(HOME)/bin

clean:
	rm -f $(TARGETS)
