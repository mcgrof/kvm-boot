#!/bin/bash
# Copyright (C) 2017-2018 Luis R. Rodriguez <mcgrof@kernel.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of copyleft-next (version 0.3.1 or later) as published
# at http://copyleft-next.org/.

source /etc/systemd/system/kvmboot/config

setup_single_guest_defaults()
{
	if [ -z $KVM_BOOT_NEXT_TARGET ]; then
		KVM_BOOT_NEXT_TARGET="/opt/qemu/linux-next.qcow2"
	fi

	if [ -z $KVM_BOOT_USE_NEXT_TARGET ]; then
		KVM_BOOT_USE_NEXT_TARGET="-hdb $KVM_BOOT_NEXT_TARGET"
	fi
}

allow_user_defaults()
{
	if [ -z $KVM_BOOT_VDE_SOCKET ]; then
		KVM_BOOT_VDE_SOCKET="/var/run/qemu-vde.ctl"
	fi

	if [ -z $KVM_BOOT_QEMU ]; then
		KVM_BOOT_QEMU=$(which qemu-system-x86_64)
	fi

	if [ -z $KVM_BOOT_TARGET ]; then
		KVM_BOOT_TARGET="/opt/qemu/opensuse-leap-42.2.img"
	fi

	if [ -z $KVM_BOOT_USE_TARGET ]; then
		KVM_BOOT_USE_TARGET="-hda $KVM_BOOT_TARGET"
	fi

	if [ ! -z $KVM_BOOT_SINGLE_GUEST ]; then
		setup_single_guest_defaults
	fi

	if [[ -z $KVM_BOOT_EXTRA_DEV_0001 ]]; then
		KVM_BOOT_EXTRA_DEV_0001=""
	fi

	if [ -z $KVM_BOOT_MEM ]; then
		KVM_BOOT_MEM="4096"
	fi

	if [ -z $KVM_BOOT_CPUS ]; then
		KVM_BOOT_CPUS="4"
	fi

	if [ -z $KVM_BOOT_ENABLE_GRAPHICS ]; then
		KVM_BOOT_ENABLE_GRAPHICS=false
	fi

	if [ -z $KVM_BOOT_USE_GRAPHICS ]; then
		if [[ $KVM_BOOT_ENABLE_GRAPHICS == true ]]; then
			KVM_BOOT_USE_GRAPHICS=""
		else
			KVM_BOOT_USE_GRAPHICS="-nographic"
		fi
	fi

	if [ -z $KVM_BOOT_KERNEL_APPEND ]; then
		# Only used if you are asking to boot into a specific
		# development kernel
		KVM_BOOT_KERNEL_APPEND=(
			debug
			audit=0
			load_ramdisk=2
			root=/dev/sda1
			# WTF 'stty -F /dev/ttyS0 -a' reports one thing, yet
			# 'dmesg| grep tty' reports another. I give up, this
			# should work... best bet is just to get networking
			# working.  For details on tty issues:
			# see: https://lists.gnu.org/archive/html/qemu-devel/2013-06/msg01507.html
			console=ttyS0,115200n
			console=tty0
			vga=normal
			dyndbg=\"file firmware_class.c +p\; file arch/x86/kernel/init.c +p\"
			rw
			drbd.minor_count=8
			max_part=63
			#cgroup_no_v1=all
			#cgroup_disable=all
			#ipv6.disable_ipv6_mod=1
		)
	fi

	if [ -z $KVM_BOOT_ISO_PATH ]; then
		KVM_BOOT_ISO_PATH="/opt/isos"
	fi

	if [ -z $KVM_BOOT_ISO ]; then
		KVM_BOOT_ISO="$KVM_BOOT_ISO_PATH/opensuse/openSUSE-Leap-42.2-DVD-x86_64-Build0215-Media.iso"
	fi

	if [ -z $KVM_BOOT_VERBOSE ]; then
		KVM_BOOT_VERBOSE="false"
	fi
}

kvm_boot_net_require_warn_exit()
{
	echo "Your kvm-boot network is not setup, you need vde_switch"
	echo "and dnsmasq running for this to work correctly. To start"
	echo "enable and start the systemd service:"
	echo
	echo   * kvm-boot-dnsmasq.service
	exit 1
}

kvm_boot_check_network_active()
{
	systemctl status kvm-boot-vde2.service
	if [ $? -ne 0 ]; then
		return 1
	fi
	systemctl status kvm-boot-dnsmasq.service
	if [ $? -ne 0 ]; then
		return 1
	fi
	return 0
}

kvm_boot_exit_if_no_network_setup()
{
	kvm_boot_check_network_active
	if [ $? -ne 0 ]; then
		kvm_boot_net_require_warn_exit
	fi
}
