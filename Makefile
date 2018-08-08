BASHRC?= $(HOME)/.bashrc
INSTALL_DIR?= ~/bin
PROGS := kvm_boot_lib.sh install-kvm-guest setup-kvm-switch kvm-boot
SETUP_FILE := .kvmboot-setup

all: $(PROGS)

install: $(PROGS)
	@mkdir -p $(INSTALL_DIR)
	@$(foreach var,$(PROGS), \
		if [ ! -f $(FSTESTS)/$(var) ]; then \
			echo SYMLINK $(var) on $(INSTALL_DIR); \
			ln -sf $(shell readlink -f $(var)) $(INSTALL_DIR); \
		fi; \
		)
	@if [ -f $(BASHRC) ]; then \
		if ! grep $(SETUP_FILE) $(BASHRC) 2>&1 > /dev/null ; then \
			echo "REFER $(SETUP_FILE) on $(BASHRC)" ;\
			cat .bashrc >> $(BASHRC) ;\
		fi \
	else \
		echo "INSTALL $(BASHRC)" ;\
		echo "#!/bin/bash" >> $(BASHRC) ;\
		cat .bashrc >> $(BASHRC) ;\
		chmod 755 $(BASHRC) ;\
	fi
	@if [ ! -f $(HOME)/$(SETUP_FILE) ]; then \
		echo INSTALL $(SETUP_FILE) $(HOME) ;\
		install $(SETUP_FILE) $(HOME) ;\
	fi

uninstall:
	@$(foreach var,$(PROGS), \
		if [ -f $(INSTALL_DIR)/$(var) ]; then \
			echo RM $(INSTALL_DIR)/$(var); \
			rm -f $(INSTALL_DIR)/$(var) $(FSTESTS); \
		fi; \
		)
