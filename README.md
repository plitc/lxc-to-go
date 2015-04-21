
LICENSE
=======
* BSD 2-Clause

Background
==========
* create an lxc environment for mobile devices and servers

Benefits of Goal Setting
========================
* rapid lxc deployment for mobile devices and servers

WARNING
=======
* lxc-to-go is experimental and its not ready for production. Do it at your own risk.

Dependencies
============
* Linux
   * NEED Kernel Upgrade on Wheezy (default 3.2 to 3.16 wheezy backports)
   * (grub/kernel compatibility for lxc)
   * sh (as dash/bash)
   * bridge-utils
   * screen
   * lxc

* LXC Container: managed
   * debian jessie
   * systemd-sysv
   * iputils-ping
   * traceroute
   * isc-dhcp-server
   * unbound
   * radvd

Features
========
* create basic templates
   * deb7 template
   * deb8 template

* create "managed" lxc for:
   * routing (layer 3)
   * dhcp server
   * dns server
   * ipv6 router advertisement

* "managed" lxc container:
   * proxy_arp/ndp support (server mode)
   * dhcp/ra support (desktop mode)

Platform
========
* Linux
   * Debian 8/jessie (recommended)
   * Debian 7/wheezy

Usage
=====
```
    WARNING: lxc-to-go is experimental and its not ready for production. Do it at your own risk.

    # usage: ./lxc-to-go.sh { bootstrap | start | stop | create | delete }
```

Example
=======
* bootstrap
```
    # ./lxc-to-go.sh bootstrap

        Please Reboot your System immediately! and continue the bootstrap

    # ./lxc-to-go.sh bootstrap

    # lxc-attach -n managed (or screen attach)
```

* start
```
```

* stop
```
```

* create
```
```

* delete
```
```

Diagram
=======
* lxc-to-go bootstrap (prototype > 0.11)
![lxc-to-go_schema](/content/lxc-to-go_schema_.jpg)

* lxc-to-go for servers (prototype > 0.9)
![lxc-to-go_servers](/content/lxc-to-go_servers_.jpg)

* lxc-to-go for mobile devices (prototype 0.6)
![lxc-to-go_desktop](/content/lxc-to-go_desktop_.jpg)

Screencast
==========

Errata
======
* 21.04.2015: Starting VirtualBox AdditionsVBoxService: error: VbglR3Init failed with rc=VERR_FILE_NOT_FOUND failed!
```
   STRACE: open("/dev/vboxguest", O_RDWR|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```
* 21.04.2015: "lxc-to-go < 0.13.5" add unnecessary kernel options on debian 7 wheezy (not critical)
* 11.04.2015: 

TODO
====
* 17.04.2015: useful ipv6 routing
* 16.04.2015: support for zfs/btrfs lxc-clone templates

