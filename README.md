kvm-boot
========

kvm-boot is for folks who work on Linux kernel development based on linux-next
and want to test kernel compiles fast with an extremely lightweight and very
easy to read simple test script. It is currently x86_64 biased, however some
initial tests have been done to make it work with other architectures.

Getting linux-next
------------------

Using linux-next should let you do development on any part of the Linux kernel
and submit patches for that respective subsystem. It avoid you having to clone
tons of separate branches.

	git clone https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git

When doing development you can do:

	git checkout -b 20160608-mytopic next-20160608

Each day after this just do, for example on 20160609:

	git fetch
	git checkout -b 20160609-mytopic
	git branch --set-upstream-to=origin/master 20160609-mytopic
	git rebase --onto origin/master

This will keep locally all of your old development branches and let you keep
rolling with the latest development tress bunched together into one.

Build
-----

There are not build requirements. Its all shell.

Install
-------

Just run:

	$ cd ~/devel/kvm-boot/
	$ make install

Setup
-----

# Networking setup

When you decide you need to spawn guests just run this prior to spawning guests:

	$ sudo ~/bin/setup-kvm-switch

You may need to just set the environment variable KVM_BOOT_NETDEV with
whatever interface you use for your connection to the Internet, and after
this after spawning you should see:

	Setting up switch on tap0
	net.ipv4.ip_forward = 1

If that does not work refer to the section: "Overriding defaults with
environment variables for setup-kvm-switch" below for more environment
variables you might need to fine tune.

That should get your system setup for networking. It will allow your guests to
run using DHCP with full networking. Your hosts will have a functional access
to the network so long as your host does too. This setup strives for sensible
defaults that might work for most, allowing you to override with environment
variables.

# KVM use for users

You will want to enable use of kvm for users. Typically this can be done
by letting the user be part of the kvm group. This will be important also
for networking purposes, in particular you will want the /var/run/qemu-vde.ctl
directory owned by kvm group, and files created as well. Using the sticky
bit should suffice.

Usage
-----

There are two main uses, direct kernel file boot (be sure to read the section
below "Direct file kernel configuration"):

	$ kvm-boot -k arch/x86/boot/bzImage

Raw image boot:

	$ kvm-boot -b

Raw image boot using a specific main image and custom secondary development
disk:

	$ kvm-boot -t /opt/qemu/some.img -n /opt/qemu/linux-next.qcow2

Additionally if you are working on qemu development you can always use:

	$ kvm-boot -d # use $HOME/devel/qemu/x86_64-softmmu/qemu-system-x86_64

# Overriding defaults with environment variables for kvm-boot

You can override many default parameters by just using environment variables.
We enable this mechanism to be able to allow for customizations without
expanding on the number of supported arguments for all possible parameters we
may pass to qemu.

The list of variables you can override are viewable on the function
allow_user_defaults() on kvm-boot, we list them and document them here:

  * KVM_BOOT_VDE_SOCKET: qemu socket to when vde2 is used for networking
  * KVM_BOOT_QEMU: qemu binary to use
  * KVM_BOOT_TARGET: primary target qcow2 image to use for boot disk
  * KVM_BOOT_USE_TARGET: enables specifying precise disk parameter to use for
    primary boot disk
  * KVM_BOOT_NEXT_TARGET: secondary development disk to use, where you have your
    git git trees and you compile your kernels
  * KVM_BOOT_USE_NEXT_TARGET: enables specifying precise disk parameter to use
    for qemu for the secondary development disk
  * KVM_BOOT_MEM: amount of memory to use in MiB
  * KVM_BOOT_CPUS: number of CPUs to use
  * KVM_BOOT_ENABLE_GRAPHICS: whether or not to enable graphics support, set
    this to true during your initial setup, and remove that line once things
    are ready.
  * KVM_BOOT_KERNEL_APPEND: set of kernel parameters to use when booting using the
    direct file mechanism
  * KVM_BOOT: main KVM guest boot command to issue

# Overriding defaults with environment variables for setup-kvm-switch

Network configuration support is provided by setting up a switch using one
of you networking interfaces which has network connectivity, and using dnsmasq
for the guests on it. You can configure different options for the switch by
using custom variables on your environment for setup. We document below only
a few basic ones you might need to change for now.

  * KVM_BOOT_NETDEV: you will very likely need to modify this unless wlp3s0 also
    happens to be your main networking interface.
  * KVM_BOOT_TAP_DEV: name of the tapdev you will want to use for the switch setup.
    You might only need to change this if you happen to for example using tun
    already for an existing VPN network you always have running. The default is
    tap0.
  * KVM_BOOT_NETWORK: address for your guests network. The default is 192.168.53.0
  * KVM_BOOT_NETMASK: netmask for your guest network. The default is 255.255.255.0.
  * KVM_BOOT_GATEWAY: gateway IP address you want to use for your guest network,
    don't worry we'll configure things for you. The default is 192.168.53.1.
  * KVM_BOOT_DHCPRANGE: the DCHP range you wish to use. The default setting is
    192.168.53.2,192.168.53.254
  * KVM_BOOT_DNSMASQ_RUN_DIR: the run directory your dnsmasq prefers to use. This
    defaults to /var/lib/dnsmasq/

# Overriding defaults with environment variables for install-kvm-guest

As an alternative to using command like arguments with install-kvm-guest you
can use environment variables. Some of the basic environment variables used for
kvm-boot are also used with install-kvm-guest.

  * KVM_BOOT_ISO_PATH: path where your isos are located
  * KVM_BOOT_ISO: ISO to use for installation

# Example minimum .bashrc settings

You really might only need to set thes on your .bashrc to get this to work right
away:

	export KVM_BOOT_NETDEV=eth0
	export KVM_BOOT_TARGET=/opt/qemu/debian-x86_64.qcow2
	export KVM_BOOT_NEXT_TARGET=/opt/qemu/mcgrof-dev-20170605.img

Requirements
------------

You should have installed on your development system where you will
run guests from:

  * vde2
  * dnsmasq
  * iptables

Project goals
-------------

# What we strive for

  * We *want* mimimal kernel compile times
  * We *want* a super easy-to-read simple script
  * We *want* a distribution-agnostic solution
  * We *want* _full_ solid network connectivity for the guest kernels
  * We *want* network connectivity to be *super easy* to setup
  * We *want* to allow for qemu-development in a simple way
  * We *want* to rely on screen(1) /usr/bin/screen
  * We *want* suspend to RAM / disk & resume to work on hypervisor host
  * We *want* to avoid having to copy over linux sources over and over again

# What we want to avoid

  * We *do not* want to deal with complex initramfs setup
  * We *do not* want to require root access for guest spawning
  * We *do not* want to deal with the complex network bridge setup
  * We *do not* want to deal with complex test infrastructure
  * We *do not* want to deal with fancy GUI crap

The two methods to boot guests
------------------------------

When working on kernel development you typically have two ways to use KVM.
They each have their pros and cons. We support both.

 * Direct file: Passing qemu -kernel and -initrd for direct boot use
 * Disk images: using qcow2 disk image

We document each case further below.

# Direct file

	$ kvm-boot -k arch/x86/boot/bzImage

This method allows you to compile kernel code on your local filesystem, and
just boot into those kernels. Typically this does require initramfs setup,
however, we provide initramfs inference support. Initramfs inferences support
relies on the *premise* that distributions have a proper /sbin/installkernel
script.

## Direct file boot notes with modules

The direct file boot method will use the specified kernel and initramfs. You
hope that the required modules are present on the initramfs, typically there
is no easy way to ensure this in distribution-agnostic way. After the kernel
boots with its initramfs, it will look for modules in /lib/modules/$(uname -r)/
and if the modules required to complete boot are not present there boot will
fail.

You could mount the image and copy over the /lib/modules/ contents over, or scp
them over to the guest if you get the guest booted somehow, however this is all
fragile.

Because of these issues (and more) the below instructions recommend striving
to get a kernel built with enough options to boot most guests, but also
force enabling a few kernel configuration options as built-in.

## Direct file kernel configuration

Building kernels should be fast. Distribution kernels have tons of options
enabled which slow down the kernel compilation process, and this also means
it slows you down as a developer. You should only need to build kernels with
enough bells and whistles to enable booting your host system and your target
guest system. We will provide instructions on how to accomplish this and
describe current known limitations to optimize this.

We rely on the kernels' generic distro-agnostic install target:

	make -j
	sudo make modules_install install

As documented in the subsection below this relies on /sbin/installkernel.
One of the tricky aspects of using this method is you need a kernel with
proper an initramfs which will also work for your KVM guest. Experience shows
relying on /sbin/installkernel does not do enough to ensure for this, even
if you have all the guest kernel configuration options enabled as modules.

The first inclination may be to try to enable all the required KVM guest
kernel configurations as built-in (=y) but this also can suffer from some
timing issues at boot. For this reason we provide a basic qemu x86_64 config
file you can use with enough suggested kernel configuration options for the
guest set to be built-in (=y) so you can at least try to get serial working
and use the *much more reliable* networking guest access via ssh.

For simplicity's sake we assume you'll be doing development based on linux-next,
and that your development willl be based on the latest linux-next tag. For the
sake of testing we will refer to our x86_64 guest as piggy, and so its kernel
configuration as configs/piggy-x86-64-next.config -- this is a symlink, the
actual file it points to have a date, which reflects the linux-next tag from
which the kernel configuration was based on. We'll provide updates to it when
deemed necessary, typically when there is a kconfig rename which might distrupt
this functionality.

Using the guest kernel configuration won't be enough so you can optionally boot
your own system with the same kernel and initramfs -- should you want to try to
do that.  If you do want to install a kernel which will also work with your
system (not the guest) you can do as follows to start a base kernel
configuration. Do this from the linux-next git tree for kernel development.

First get your distribution's latest kernel. This may vary depending on your
distribution. Some distributions have a kernel of the day (KOTD). For instance
OpenSUSE has their KOTD here:

https://en.opensuse.org/openSUSE:Kernel_of_the_day

You will want to install and boot into a recent kernel on your laptop/server
given linux-next has the latest development kernel code, we will rely on 'make
localmodconfig' and this could break if modules are renamed upstream or if
config values change over time. Using a recent kernel will try to keep our
resulting configuration on par with what your distribution provided.

	cd ~/linux-next/
	cp /boot/config-$(uname -r) .config
	cp ~/devel/kvm-boot/configs/piggy-x86-64-next.config .

	# Reduce the kernel configuration to require only what your local system
	# needs. If you compile now this *should* work on your system.
	make localmodconfig

	# Now merge the KVM guest requirements we recommend due to module
	# issues.
	./scripts/kconfig/merge_config.sh -m .config piggy-x86-64-next.config

	# Now compile away ! And then install
	make -j 4

	# this method of installing is documented further below
	sudo make modules_install install

You don't have to boot into this new kernel on your system/laptop/whatever
system you are building from, but you *can* try if you want to -- this may work
or not, it depends...

Additionally note that booting into linux-next may mean a failed boot either on
your main system or your guest, given that linux-next is a moving target, so
there may be bugs in linux-next which were not there in previous linux-next
tags. We assume you are prepared for this, will want to engage upstream if
there are issues or want to fix th issues.

If you cannot get the above optimized kernel to boot on your guest start again
and skip the 'make localmodconfig' as that cleary is removing some components
not captured in piggy-x86-64-next.config which you do need.

Now just try booting the damn guest !

	kvm-boot

Your tty may or may not work, notes on this below. What you really want is to
get networking working, so somehow ensure you can get the guest IP address and
just rely on that. Its proven to be much more reliable than serial on qemu.

Also, you might think that enabling everything the guest needs as built-in
would be good too, that actually also has issues, these issuare also documented
below.

## Using an optimized kernel only for your guest with direct boot

You might think its worthy to just optimize kernel builds for your target guest
locally only, not caring if the kernels you build and install will work with
your own local system. If that's the case then first boot into the guest in
a more reliable way, using qcow2 for instance. Then, do git clone of linux-next,
and then do:

	cd ~/linux-next/
	cp /boot/config-$(uname -r) .config
	cp ~/devel/kvm-boot/configs/piggy-x86-64-next.config .
	make localmodconfig

The resulting kernel configuration can now be used as a base. scp that file out
onto your local system and then use scripts/kconfig/merge_config.sh to ensure
you enable as built-in a few key config options:

	./scripts/kconfig/merge_config.sh -m .config piggy-x86-64-next.config

Now build and install:

	make -j 4
	sudo make modules_install install

This kernel build will for sure build much faster, however it will very likely
not boot on your local system. Be sure to avoid booting into it on your system.
If you'd like to distinguish these builds somehow you can use any file with
the prefix "localversion-" on the ~/linux-next/ build directory. For instance
I use: localversion-mcgrof and it has the following contents:

	$ cat localversion-wireless
	-mcgrof-piggy-dev

## Issues with qemu tty

Refer to the section 'Determing what tty properties to use' under tips and
tricks. It turns out what this reports and the output from dmesg often differ.
Next, sometimes the tty comes up and lets you use it to log in. Other times it
does not. If you boot and it does not work try booting again. What the
underlying issues is, is not clear.

Additionally adding or removing multiple console= lines onto the qemu append
line (see KVM_BOOT_KERNEL_APPEND on kvm_boot_lib.sh) can often also change
behaviour, sometimes *never* allowing console to be used to log in.

Some of these issues seem to be known upstream, for details refer to:

https://lists.gnu.org/archive/html/qemu-devel/2013-06/msg01507.html

For all the above reasons we recommend you just rely on networking to log in
and get access to the guest. The console may only be realiable for output from
the kernel.

## The Linux kernel /sbin/installkernel

The Linux kernel gives you the option to have a scrip called /sbin/installkernel
which will be used on the 'make install' target of the Linux kernel. Typically
this is where distributions shove in their initramfs setup. Most distributions
rely on this script, and in fact is relied on by a slew of kernel developers to
install ther compiled Linux kernel and modules without *ever* having to deal
with local distribution shenanigans.

You should always be able to compile and install a kernel as follows on any
Linux distribution:

	$ make
	$ sudo make modules_install install

If doing this often creates too much clutter on /boot/ consider using the
install-next-kernel.sh provided in this project.

## Relying on /sbin/installkernel

We take advantage of how Linux distributions use /sbin/installkernel to ensure
proper initramfs setup for you for guest setup in a distribution agnostic way.
This does require you however to install a target kernel once.

## Enable your target development as built-in and issues

Relying on /sbin/installkernel enables you to deploy an initramfs once, and
provided you do not need to rely on that initramfs for new code deltas
(re-compile modules) that you are testing you can boot a second time by only
compiling code locally without re-generating the initramfs. One of the issues
with relying on /sbin/installkernel however is it may not provide the modules
you need to get your guest target functional. Additionally a direct boot method
will typically get your guest to pivot root out from the initramfs and then rely
on your image disk /lib/modules directory for further modules it needs outside
of the boot modules that your distribution detects it needs. For instance,
dracut would typically only stuff into the initramfs by default modules you
need to boot your development system, not a guest target.

Since you might often be doing development with what typically is enabled as
modules, and due to the possible issues with the modules you need not being on
the initramfs, in theory you'd think you can can avoid the module catch-22
issue here by just enabling your development target and its dependencies to be
compiled as built-in. This is all true, *in theory*. However this fails in
practice.

To demo the issue, first try the kernel configuration recommend under
the above section "Direct file kernel configuration", then try a secondary
kernel configuration as follows:

	cd ~/linux-next/
	# Now enable everything from both latpop / guest as built-in
	make localyesconfig
	sudo make modules_install install

Try booting into that either on your laptop or guest. If you see something
as follows, this is the issue described:

	[***   ] A start job is running for dev-sda1.device (47s / no limit)

If you *really* want to be relying on modules you can consider the other method
of development work flow with kvm-boot using raw images.

## kvm-boot initramfs setup

kvm-boot assumes you have your initramfs correctly built and installed by
relying on you installing the development kernel locally to your system *once*.
Since kvm-boot is a distribution agnostic solution we assume the developer can
always (regardless of what distribution they are using) can simply always
install kernels and modules you have compiled with:

	$ make -j 4 # compile kernel and modules

And then install the kernel and initramfs as follows:

	$ sudo make modules_install install  # installs kernel and initramfs

Distribution packaging solutions (rpm, deb) use this target and should rely
on /sbin/installkernel anyway. Intalling kernel/modules using distribution
package solutions should therefore always work as well. If relying on this
does not work it should be considered a distribution bug.

## Initramfs inference support

Current initramfs inference is rather simple and relies on you specifying the
target kernel you want to use, refer for parse_passed_kernel() for details.

## Using the latest kernel

By default kvm-boot will look for the latest installed kernel / initramfs on
/boot/ and use that. Otherwise you should specify the target kernel using -k. 
If you want to be explicit about using the latest kernel found on /boot you
can always use:

	$ kvm-boot -l

# Disk images

Using disk images is convenient to do away with all the above required setup.
We suppot qcow2 disk image format by default. You will first need to setup a
basic qemu image you can use for development purposes. You actually will want
to setup at least two disk images eventually, one for the guest image, and
another for the Linux kernel sources which you can share accross images.

To start off with build a qcow2 disk image you can use to boot qemu from. We
start off with by using an ISO and a raw qcow2 file we will use as target
raw image. For now we supply an example guest script which folks can simply
customize as they see fit to enable them to install an ISO image of their
choice onto a qcow2 image.

## qcow2 image setup

You want to setup at least 2 qcow2 disk images. One for the guest, another for
the Linux kernel sources.

### qcow2 guest image setup

You will want to create a qcow2 image, 6 GiB typically works, as we will want
to deploy our Linux kernel sources in another larger image. This should be
enough to to also carry your /boot/, we'll practice to keep it small using
the script install-next-kernel.sh on the guest when installing kernels.
This assumes you are using linux-next.git for your development work flow.

	$ qemu-img create -f qcow2 /opt/qemu/some.img 6G

### qcow2 Linux kernel development image

You'll want a secondary image you can use with much larger size so you can use
it for stashing your linux kernel sources.

	$ qemu-img create -f qcow2 /opt/qemu/linux-next.qcow2 50G

To copy over the linux sources you can do from the host:

	$ sudo modprobe nbd max_part=16
	$ sudo qemu-nbd -c /dev/nbd0 /opt/qemu/linux-next.qcow2
	# Create primary parition and take up all the space
	$ sudo fdisk /dev/nbd0
		Command (m for help): n
		...
		Select (default p): p
		...
		Partition number (1-4, default 1): 1
		...
		First sector (2048-20971519, default 2048): 
		...
		Last sector, +sectors or +size{K,M,G,T,P} (2048-20971519, default 20971519): 
		...
		Command (m for help): t
		...
		Partition type (type L to list all types): 83
		...
		Command (m for help): w
	$ sudo partprobe /dev/nbd0
	$ sudo mkfs.ext4 /dev/nbd0p1
	$ sudo mkdir -p /mnt/linux-next
	$ sudo mount /dev/nbd0p1 /mnt/linux-next
	$ sudo cp -a ~/linux-next/ /mnt/linux-next
	$ sudo umount /mnt/linux-next
	$ sudo qemu-nbd -d /dev/nbd0
	# nbd has buggy suspend/resume, better remove it
	$ sudo modprobe -r nbd

This image is exposed to the kvm-boot guest kernel we boot later as a secondary
disk, using qemu -hdb parameter.

## install-kvm-guest

install-kvm-guest scripts can help you install an ISO image onto a target qcow2
image file, with a fully functionaly network in place, and exposing the
linux-next development target image as a secondary disk. Example use:

	$ ./install-kvm-guest -i /opt/isos/some.iso \
			      -t /opt/qemu/some.img \
			      -n /opt/qemu/linux-next.qcow2

That will by defalut use SDL to kick off your installation. Follow the steps to
install the guest, be sure to install and enable SSH, some distros disable this
by default.

You can configure the install as you wish, just be sure to dedicate the larger
disk for your say, $HOME/$USER/data/ partition.

Some installers are rather pesky and assume the larger disk is where the target
install should be, and sometimes they make it rather difficult through the GUI
to modify the fact that you just want the larger disk to be used for a home
subdirectory for you. So you may want to just skip the -n option and use: -n
none:

	$ ./install-kvm-guest -i /opt/isos/some.iso \
			      -t /opt/qemu/some.img \
			      -n none

If you do this can later expose the disk on a second boot and configure it to
be mounted on $HOME/$USER/data as follows on /etc/fstab:

	/dev/sdb1	/home/mcgrof/data	ext4    errors=remount-ro 0       1

Once done with the install you can use the *same exact command* to boot off the
hard drive provided the ISO gives you that option (most distros do this). You
want to do a first boot to configure the guest a bit for the last touches so
you can start hacking away in a nice development environment.

Be sure to expose the development disk so you can configure a mount point for
it as recommended above, so *make sure* to use the -n option with the respective
linux-next.qcow2 file.

## Preparing for first kvm-boot use on guest

Once you are done with the installation of the guest there are a few more
things you will want to set up to be a happy camper Linux developer using
kvm-boot, you can set these up using the same install-kvm-guest script as
described above and booting from the hard disk.

You will want to do the following:

  * console access - useful for early crashes or in case networking dies
  * grub tty setup - lets you select your kernels on the boot prompt
  * write down the guest IP address - these should be static after first DHCP

### Setting up console and grub

Edit /etc/securetty and ensure you have the entries:

	ttyS0
	ttyS1
	ttyS2

You will also need to setup the getty to spawn. This will vary depending
on what init system you are using. If you are using old init you will
need to add the entries on /etc/inittab:

	T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100
	T1:2345:respawn:/sbin/getty -L ttyS1 115200 vt100
	T2:2345:respawn:/sbin/getty -L ttyS2 115200 vt100

Some systems (SLE11-SP4) uses agetty, its not much different:

	S0:12345:respawn:/sbin/agetty -L 115200 ttyS0 vt102
	S1:12345:respawn:/sbin/agetty -L 115200 ttyS1 vt102
	S2:12345:respawn:/sbin/agetty -L 115200 ttyS2 vt102

On systemd this is done as follows:

	systemctl enable console-getty.service getty@ttyS0.service
	systemctl enable console-getty.service getty@ttyS1.service
	systemctl enable console-getty.service getty@ttyS2.service

It is *imperative* that yo do not screw up and re-use one label or device name
above, for instance if you use ttyS0 twice things will not work. Likewise for
the first tag on inittab, if you use S0 twice it will not work.

Finally, edit the guest /etc/default/grub and ensure you have these entries:

	GRUB_CMDLINE_LINUX="console=ttyS1,115200 console=ttyS1"
	GRUB_TERMINAL=serial

The last line mentioned above enables you to select a kernel through the
grub prompt through serial.

If you are GRUB 0.9x (SLE11-SP4) -- then you will instead to edit the file
/boot/grub/menu.lst and add the above entry for console to the kernel line.
For instance I have on SLE11-SP4:

	kernel /boot/vmlinuz-3.0.101-63-default root=/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001-part2 resume=/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001-part1 console=ttyS1,115200 console=ttyS1 crashkernel=256M-:128M showopts vga=0x314

I have removed the splash=silent entry. To set up the equivalent of
GRUB_TERMINAL on grub 0.97 you can use the following but upon testing this does
seem to just generate a prompt asking for any input, displaying the boot prompt
does not seems work. Add this to your /boot/grub/menu.lst  after the timeout
line, for instance my menu.lst file starts with:

	default 0
	timeout 8
	serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
	terminal --timeout=4 serial console

This will use ttyS0 (where you launch kvm-boot from). Use unit=1 to use ttyS1,
for instance. The "terminal" line specifies where grub 0.97 we'll throw the
boot prompt by default in the timeout specified. Each second it will display
"Press any key to continue." on both serial and console, if it receives input
from any, it will then display the boot prompt there. The first entry is where
the default grub 0.97 will use to display the boot prompt. Above we are
being explicit we want the boot prompt to go to serial. In theory this should
work as [serial is documented on TLDP for grub 0.97], however in practice this
does not seem to work. As such if you really need to pick kernels when booting
with grub 0.97 and kvm-boot you should just consider enabling

	KVM_BOOT_ENABLE_GRAPHICS=true

This will ensure you get a boot prompt through the qemu SDL interface.

[serial is documented on TLDP for grub 0.97]: http://www.tldp.org/HOWTO/Remote-Serial-Console-HOWTO/configure-boot-loader-grub.html

After grub setup this you will need to run the boot loader refresh script for
your distribution so that the grub configuration files get updated.

  * Debian: update-grub
  * OpenSUSE: update-bootloader --refresh

If you are having issues with tty setup ensure to enable graphics (SDL by
default) with the variable KVM_BOOT_ENABLE_GRAPHICS=true on your .bashrc
so you can have a way to log in. Remove that line once you know everything
is properly set up and even networking is up.

## Booting development guest for the first time

Provided you could setup all the above correctly you should be ready to go.
Try now:

	$ kvm-boot -t /opt/qemu/some.img -n /opt/qemu/linux-next.qcow2

You should see something like this on stdout:

	Going to boot directly onto image disk
	qemu-system-x86_64: -monitor pty: char device redirected to /dev/pts/9 (label compat_monitor0)
	qemu-system-x86_64: -chardev pty,id=ttyS1: char device redirected to /dev/pts/11 (label ttyS1)
	qemu-system-x86_64: -chardev pty,id=ttyS2: char device redirected to /dev/pts/12 (label ttyS2)

We purposely redirect two ttys to a PTS so you can then use screen to attach
to them (root should not be required). You can also get access to the qemu
control interface using screen as well:

	$ screen /dev/pts/9
	$ screen /dev/pts/11
	$ screen /dev/pts/12

## Sshing into your guest image

Make sure to write down the IP address of the guest before using kvm-boot, you
should then be able to ssh into it. There is a slew of issues which can occur
when using console (see the WTF note on kvm-boot), for this reason the author
has relied mostly on ssh for access to the system.

Tips and tricks
----------------

Below are list of collection of tips and tricks which may help you further
in either diagnosign issues or help you with your development setup.

# Booting with -k for the first time

Booting qemu with a specific access works great but it obviously will not
work well if the kernel options for the emulated qemu hardware are not enabled.
Over time kconfig options change and when they do even if you copy over a
functional kernel .config over from a functional old boot, things may not
work on the fresh new kernel compile. To verify 'kvm-boot -k' works boot
first with a distribution kernel that you know *does* work with qemu.

In the future we'll provide a base .config you can use for qemu, but this
probably really should just be a 'make qemuconfig' option upstream that merges
the required options. The hard thing with this argument is that contrary to
'make kvmconfig' and 'make xenconfig', qemu targets vary widely, so this makes
this a questionable thing to do in a sensible way.

What we *really* need is way to query a target machine for a kernel for a
specific target, but a lot more work needs to be done before we get there.
For some thoughts on this see this thread on adding a CONFIG symbol as a
module attribute:

https://lkml.kernel.org/r/20160818175505.GM3296@wotan.suse.de

# Keeping your /boot small

When using qcow2 images you may often find /boot can fill up quickly when
doing a lot of development. If you are working with a linux-next development
work flow you can consier copying over the file install-next-kernel.sh and
using that when installing your kernels, it will make sure to always remove
old linux-next instances, while keeping your distribution kernels.

# Determing what tty properties to use

If you run into issues with your tty settings and qemu (know that qemu tty can
be buggy), you can use stty to query tty settings that you should use in case
what you have specified on boot through grub did not go through for on reason
or another.

	root@piggy:~# stty -F /dev/ttyS1
	speed 115200 baud; line = 0;
	-brkint ixoff -imaxbel iutf8
	-iexten

This confirms that my ttyS1 was setup correctly as I expected it with 115200
baud rate. If this is different from what you specified on your grub
configuration this may be why you are having issues.

# Ensuring your kernel booted with the right tty settings

If you are not sure if your kernel booted with the right settings just
query /proc/cmdline for instance:

	linux-pleh:~ # cat /proc/cmdline
	BOOT_IMAGE=/boot/vmlinuz-4.4.22-1-default root=UUID=4b38d06b-51f8-4c44-b339-f66ff4bd0884 console=ttyS1,115200 console=ttyS1 resume=/dev/sda1 splash=silent quiet showopts

# Testing kernel suspend / resume with qemu for kernel development

Often you may need to test suspend / resume on a target guest. The following
tips should help you get this done easily. First let's pretend we got the
following from kvm-boot on stdout. Note, that if you used GRUB_TERMINAL=serial
or GRUB_TERMINAL=console you will have your immediate stdout contended with
the grub prompt so there will be only a small period of time you could capture
this output:

	Going to boot directly onto image disk
	qemu-system-x86_64: -monitor pty: char device redirected to /dev/pts/9 (label compat_monitor0)
	qemu-system-x86_64: -chardev pty,id=ttyS1: char device redirected to /dev/pts/11 (label ttyS1)
	qemu-system-x86_64: -chardev pty,id=ttyS2: char device redirected to /dev/pts/12 (label ttyS2)

This tells you, that you can control the qemu guest via the qemu monitor
interface using /dev/pts/9. To trigger a suspend on a guest you either use the
respective userspace tools depending on what init system is used:

	# Old init
	root@piggy:~# pm-suspend
	# On systemd, suspends to ram

	# These may fail.. enabled via distro choice it seems ?
	root@piggy:~# systemctl hibernate
	Failed to hibernate system via logind: Sleep verb not supported
	root@piggy:~# systemctl hybrid-sleep
	Failed to put system into hybrid sleep via logind: Sleep verb not supported

If you want to disregard the preferred userspace tool way, you can do force
suspend to ram or disk as follows:

	# To query what options are available
	root@piggy:~# cat /sys/power/state
	freeze mem disk

	# To trigger suspend to ram
	root@piggy:~# echo mem > /sys/power/state

	# To resume the target, from your hypervisor you can issue the following
	# command to the pts on the control interface for the qemu instance,
	# note that this qemu interface may be a bit buggy and often you may
	# need to issue this command up to 4 times:
	$ echo system_wakeup | socat - /dev/pts/9,raw,echo=0,crnl

	# I guess this is hibernate, however my targets immediately resume.
	root@piggy:~# echo disk > /sys/power/state

TODO
----

  * Document how to get direct raw access to disk for filesystem benchmarking and
    testing.
  * Make sure the above intructions work for most distributions and adjust as
    needed
  * If a target uses GRUB_TERMINAL=serial or GRUB_TERMINAL=console you will
    have your immediate stdout contended with the grub prompt so there will be
    only a small period of time you could capture the output of the actually
    used pts for each serial console and qemu control interface. This means
    one often has to CTRL-C and restart the command until one was able to
    capture the output somehow. We should instead redirect this to a file
    somehow or figure out a nice way to query this from the process spawned?
