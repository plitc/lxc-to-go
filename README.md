
Background
==========
* create an lxc environment for mobile devices (and server)

Benefits of Goal Setting
========================
* rapid lxc deployment for mobile devices (and server)

WARNING
=======
* lxc-to-go is experimental and its not ready for production. Do it at your own risk.

Dependencies
============
* Linux
   * screen
   * lxc
   * bridge-utils
   * sh (as dash/bash)

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
![lxc-to-go](/content/lxc-to-go_.jpg)

Screencast
==========

Errata
======
* 11.04.2015 : 

TODO
====
* 16.04.2015: support for zfs/btrfs lxc-clone templates

