install: kvm_boot_lib.sh guest-install setup-kvm-switch kvm-boot
	mkdir -p ~/bin/
	cp kvm_boot_lib.sh ~/bin/
	cp setup-kvm-switch ~/bin/
	cp kvm-boot ~/bin/
	cp guest-install ~/bin/
