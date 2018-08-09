#!/bin/bash
# Copyright (C) 2017-2018 Luis R. Rodriguez <mcgrof@kernel.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of copyleft-next (version 0.3.1 or later) as published
# at http://copyleft-next.org/.

source /etc/systemd/system/kvmboot/config

setup_headers()
{
	if [ -z $KVM_BOOT_LIB_DIR ]; then
		KVM_BOOT_LIB_DIR=$(dirname $0)
	fi
	source $KVM_BOOT_LIB_DIR/lib.sh
}

do_iptables_restore()
{
	iptables-restore "$@"
}

enable_ip_forward()
{
	SYSCTL_ARGS=""
	if [ "$KVM_BOOT_VERBOSE" != "true" ]; then
		SYSCTL_ARGS="-q"
	fi
	sysctl $SYSCTL_ARGS -w net.ipv4.ip_forward=1
}

flush_tables()
{
	for i in INPUT FORWARD OUTPUT; do
		iptables -F $i
	done
	iptables -t nat -D POSTROUTING 1 2>/dev/null
}

add_filter_rules()
{
	flush_tables
	if [ ! -z $KVM_BOOT_NETDEV_VPN ]; then
		iptables -t nat -A POSTROUTING -s $KVM_BOOT_NETWORK/24 -o $KVM_BOOT_NETDEV_VPN -j MASQUERADE
	fi
	iptables -t nat -A POSTROUTING -s $KVM_BOOT_NETWORK/24 -o $KVM_BOOT_NETDEV -j MASQUERADE
}

setup_nat()
{
	enable_ip_forward
	add_filter_rules "$1"
}

kill_setup()
{
	flush_tables
	rm -rf $KVM_BOOT_VDE_SOCKET
}

parse_args()
{
	while [[ ${#1} -gt 0 ]]; do
		key="$1"

		case $key in
		-r)
			kill_setup
			shift
			;;
		-k)
			kill_setup
			exit
			;;
		*)
			shift
			;;
		esac
	done
}

setup_headers
allow_user_defaults

parse_args $@

setup_nat $KVM_BOOT_TAP_DEV
