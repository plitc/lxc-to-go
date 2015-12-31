# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

Dependencies
============
* Linux
   * NEED Kernel Upgrade on Wheezy HOST (default 3.2 to 3.16 from wheezy-backports repo)
   * NEED LXC > 1.0 on Wheezy HOST (from jessie repo)
   * (kernel compatibility for lxc)
   * (grub environment)
   * sh (as dash/bash)
   * iptables / ip6tables
   * bridge-utils
   * screen
   * lxc
   * cgmanager

* LXC Container: managed
   * debian jessie
   * systemd-sysv
   * iputils-ping
   * traceroute
   * dnsutils
   * mtr-tiny
   * isc-dhcp-server
   * unbound
   * radvd

* free hard disk space requirement: 2-3 GB

