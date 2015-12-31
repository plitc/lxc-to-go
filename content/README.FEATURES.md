# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

Features
========
* create basic templates
   * deb8 template (recommended)
   * deb7 template

* create "managed" lxc for:
   * routing (layer 3)
   * dhcp server
   * dns server
   * ipv6 router advertisement

* "managed" lxc container:
   * proxy_arp/ndp support (proxy mode)
   * dhcp/ra support (bridge mode)

* transparent network flow

* wlan bridge support thanks to proxy_arp/ndp

* enable rp_filter by default

* simple "template/flavor hooks" for general purposes

* provisioning
   * provisioning templates
   * multiport support (up to 20)

```
   # ./lxc-to-go-template.sh
```

* /usr/local/sbin symbolic link support

```
   lxc-to-go
   lxc-to-go-provisioning
   lxc-to-go-template
```

* LXC inside LXC
   * allow lxc-to-go to run within a container with web-panel
![lxc-inside-lxc](/content/lxcwebpanel.png)

* restricting container view of dmesg

* enable PulseAudio Service for X11 LXC Container

```
    # lxc-attach -n x11_lxc
    # su lxctogo
    # PULSE_SERVER=192.168.253.253 chromium &
```

* BTRFS subvolume snapshot support

