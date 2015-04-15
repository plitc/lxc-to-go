
Background
==========
* create an lxc environment for mobile devices

Benefits of Goal Setting
========================
* rapid lxc deployment for mobile devices

WARNING
=======

Dependencies
============
* Linux (Debian 8/jessie)
   * screen
   * lxc
   * bridge-utils

* Linux (LXC Container: managed)
   * debian jessie
   * systemd-sysv
   * iputils-ping
   * traceroute
   * isc-dhcp-server
   * unbound
   * radvd

Features
========

Platform
========
* Linux (Debian 8/jessie)

Usage
=====
```
    # usage: ./lxc-to-go.sh { bootstrap | start | stop | create | delete }
```

Example
=======
```
    # ./lxc-to-go.sh bootstrap

        Please Reboot your System immediately! and continue the bootstrap

    # ./lxc-to-go.sh bootstrap

    # lxc-attach -n managed
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

