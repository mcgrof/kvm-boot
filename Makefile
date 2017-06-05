install: kvm_boot_lib.sh install-kvm-guest setup-kvm-switch kvm-boot
	mkdir -p ~/bin/
	cp -f kvm_boot_lib.sh ~/bin/
	cp -f setup-kvm-switch ~/bin/
	cp -f kvm-boot ~/bin/
	cp -f install-kvm-guest ~/bin/
