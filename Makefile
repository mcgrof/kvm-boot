BASHRC?= $(HOME)/.bashrc
PROGS := install-kvm-guest kvm-boot
KVMBOOT_CONFIGS:= config dnsmasq.conf nat.sh lib.sh
BINDIR?=/usr/bin/
SETUP_FILE := .kvmboot-setup
KVMBOOT_SYSTEMD_CONFIG_DIR=/etc/systemd/system/kvmboot/
SYSTEMD_UNIT_DIR?=/usr/lib/systemd/system/
KVMBOOT_SYSTEMD_UNITS=kvm-boot-vde2.service kvm-boot-dnsmasq.service
ID=$(shell id -u)

.PHONY: all install install-user

all: $(PROGS)

install: $(PROGS)
	@if [ $(ID) != "0" ]; then \
		echo "Must run as root" ;\
		exit 1 ;\
	fi
	@mkdir -p $(BINDIR)
	@if [ ! -d $(KVMBOOT_SYSTEMD_CONFIG_DIR) ]; then \
		echo INSTALL $(KVMBOOT_SYSTEMD_CONFIG_DIR); \
		install -d $(KVMBOOT_SYSTEMD_CONFIG_DIR) ; \
	fi
	@$(foreach var,$(KVMBOOT_CONFIGS), \
		echo INSTALL $(var) on $(KVMBOOT_SYSTEMD_CONFIG_DIR); \
		install systemd-configs/$(var) $(KVMBOOT_SYSTEMD_CONFIG_DIR); \
		)
	@echo INSTALL $(SETUP_FILE) on $(KVMBOOT_SYSTEMD_CONFIG_DIR)
	@install $(SETUP_FILE) $(KVMBOOT_SYSTEMD_CONFIG_DIR)
	@if [ ! -d $(BINDIR) ]; then \
		echo INSTALL $(BINDIR); \
		install -d $(BINDIR) ; \
	fi
	@$(foreach var,$(PROGS), \
		echo INSTALL $(var) on $(BINDIR); \
		install $(var) $(BINDIR); \
		)
	@$(foreach var,$(KVMBOOT_SYSTEMD_UNITS), \
		echo INSTALL $(var) on $(SYSTEMD_UNIT_DIR); \
		install systemd-units/$(var) $(SYSTEMD_UNIT_DIR); \
		)
	systemctl daemon-reload
	systemctl enable kvm-boot-vde2.service
	systemctl enable kvm-boot-dnsmasq.service

install-user:
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
	@echo RM $(KVMBOOT_SYSTEMD_CONFIG_DIR)/
	@rm -rf $(KVMBOOT_SYSTEMD_CONFIG_DIR)
	@$(foreach var,$(PROGS), \
		if [ -f $(BINDIR)/$(var) ]; then \
			echo RM $(BINDIR)/$(var); \
			rm -f $(BINDIR)/$(var); \
		fi; \
		)
	@$(foreach var,$(KVMBOOT_SYSTEMD_UNITS), \
		echo RM $(var) on $(SYSTEMD_UNIT_DIR); \
		rm -f $(SYSTEMD_UNIT_DIR)/$(var); \
		)
