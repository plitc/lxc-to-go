
Background
==========
* create an lxc environment for mobile devices (and servers)

Benefits of Goal Setting
========================
* rapid lxc deployment for mobile devices (and servers)

WARNING
=======
* lxc-to-go is experimental and its not ready for production. Do it at your own risk.

Dependencies
============
* Linux
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

* proxy_arp/ndp support for "managed" lxc (server mode)
* dhcp support for "managed" lxc (desktop mode)

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

    # lxc-attach -n managed
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
* lxc-to-go for servers (prototype > 0.9)
![lxc-to-go_servers](/content/lxc-to-go_servers_.jpg)

* lxc-to-go for mobile devices (prototype 0.6)
![lxc-to-go_desktop](/content/lxc-to-go_desktop_.jpg)

Screencast
==========

Errata
======
* 11.04.2015 : 

TODO
====
* 16.04.2015: support for zfs/btrfs lxc-clone templates

