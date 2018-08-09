#!/bin/bash
# Copyright (C) 2017-2018 Luis R. Rodriguez <mcgrof@kernel.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of copyleft-next (version 0.3.1 or later) as published
# at http://copyleft-next.org/.

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
	allow_user_defaults_network
}

allow_user_defaults_network()
{
	if [ -z $KVM_BOOT_NETDEV ]; then
		KVM_BOOT_NETDEV=wlp3s0
	fi

	if [ -z $KVM_BOOT_TAP_DEV ]; then
		KVM_BOOT_TAP_DEV=tap0
	fi

	# Network information, these are sane values, you can keep them
	# unless they intefere with your network, ie, if you already make use
	# of this subnet. If you don't use this subnet it should be fine.
	if [ -z $KVM_BOOT_NETWORK ]; then
		KVM_BOOT_NETWORK=192.168.53.0
	fi

	if [ -z $KVM_BOOT_NETMASK ]; then
		KVM_BOOT_NETMASK=255.255.255.0
	fi

	if [ -z $KVM_BOOT_GATEWAY ]; then
		KVM_BOOT_GATEWAY=192.168.53.1
	fi

	if [ -z $KVM_BOOT_DHCPRANGE ]; then
		KVM_BOOT_DHCPRANGE=192.168.53.2,192.168.53.254
	fi

	if [ -z $KVM_BOOT_DNSMASQ_RUN_DIR ]; then
		KVM_BOOT_DNSMASQ_RUN_DIR=/var/run/dnsmasq
	fi

	if [ -z $KVM_BOOT_DNSMASQ_PID ]; then
		KVM_BOOT_DNSMASQ_PID=$KVM_BOOT_DNSMASQ_RUN_DIR/qemu-dnsmasq-$KVM_BOOT_TAP_DEV.pid
	fi

	if [ -z $KVM_BOOT_VDE_SWITCH_PID ]; then
		KVM_BOOT_VDE_SWITCH_PID=/var/run/qemu-vde.pid
	fi

	if [ -z $KVM_BOOT_DNSMASQ_LEASE ]; then
		KVM_BOOT_DNSMASQ_LEASE=/var/lib/misc/qemu-dnsmasq-$KVM_BOOT_TAP_DEV.leases
	fi

	# Optionally parameters to enable PXE support
	if [ -z $KVM_BOOT_TFTPROOT ]; then
		KVM_BOOT_TFTPROOT=
	fi

	if [ -z $KVM_BOOT_BOOTP ]; then
		KVM_BOOT_BOOTP=
	fi

	if [ -z $KVM_BOOT_FIX_DNSMASQ_CONFLICT ]; then
		KVM_BOOT_FIX_DNSMASQ_CONFLICT="false"
	fi

	KVM_BOOT_SYSTEMD_USED="false"
	ps -ef | grep -q systemd
	if [ $? -eq 0 ]; then
		KVM_BOOT_SYSTEMD_USED="true"
	fi

	KVM_BOOT_SYSTEMD_DNSMASQ_DIR=""
	if [ "$KVM_BOOT_SYSTEMD_USED" = "true" ]; then
		KVM_BOOT_SYSTEMD_DNSMASQ_DIR=$(systemctl status dnsmasq.service | grep "\-7" | awk -F"-7" '{print $2}' | awk '{print $1}' | awk -F"," '{print $1}')
		if [ ! -d $KVM_BOOT_SYSTEMD_DNSMASQ_DIR ]; then
			KVM_BOOT_SYSTEMD_DNSMASQ_DIR=""
		fi
	fi
}

kvm_boot_dnsmask_running()
{
	if [ -f $KVM_BOOT_DNSMASQ_PID ]; then
		return 0
	else
		return 1
	fi
}

kvm_boot_warn_dnsmasq_running()
{
	PID=$(cat $KVM_BOOT_DNSMASQ_PID)
	echo "dnsmasq already running, PID: $PID, try running this to reset:"
	echo
	echo "sudo -E $KVM_BOOT_LIB_DIR/setup-kvm-switch -r"
	echo
}

kvm_boot_vde_switch_running()
{
	if [ -f $KVM_BOOT_VDE_SWITCH_PID ]; then
		return 0
	else
		return 1
	fi
}

kvm_boot_warn_vde_switch_running()
{
	PID="$(cat $KVM_BOOT_VDE_SWITCH_PID)"
	echo "vde_switch is already running on pid $PID, to reset run:"
	echo
	echo "sudo -E $KVM_BOOT_LIB_DIR/setup-kvm-switch -r"
	echo
}
