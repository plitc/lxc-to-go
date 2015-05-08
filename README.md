
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
   * NEED Kernel Upgrade on Wheezy HOST (default 3.2 to 3.16 from wheezy-backports repo)
   * NEED LXC > 1.0 on Wheezy HOST (from jessie repo)
   * (kernel compatibility for lxc)
   * (grub environment)
   * sh (as dash/bash)
   * iptables / ip6tables
   * bridge-utils
   * screen
   * lxc

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

HOST (Package) Dependencies
=================
* Debian 7 Wheezy HOST
```
   [WHEEZY]: debootstrap libcap2-bin libpam-cap
   [WHEEZY-BACKPORTS]: initramfs-tools
   [WHEEZY-BACKPORTS]: firmware-linux-free irqbalance libcap-ng0 libglib2.0-0 libglib2.0-data libnuma1 linux-compiler-gcc-4.6-x86 linux-headers-3.16.0-0.bpo.4-amd64 linux-headers-3.16.0-0.bpo.4-common linux-image-3.16.0-0.bpo.4-amd64 linux-kbuild-3.16 shared-mime-info
   [WHEEZY-BACKPORTS]: firmware-linux-nonfree
   [WHEEZY-BACKPORTS]: build-essential dpkg-dev g++ g++-4.7 libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl libdpkg-perl libfile-fcntllock-perl libstdc++6-4.7-dev libtimedate-perl module-assistant
   [JESSIE]: dh-python init-system-helpers libalgorithm-c3-perl libapparmor1 libarchive-extract-perl libcgi-fast-perl libcgi-pm-perl libclass-c3-perl libclass-c3-xs-perl libcpan-meta-perl libdata-optlist-perl libdata-section-perl libdb5.3 libfcgi-perl libffi6 liblog-message-perl liblog-message-simple-perl libmodule-build-perl libmodule-pluggable-perl libmodule-signature-perl libmpdec2 libmro-compat-perl libpackage-constants-perl libparams-util-perl libperl4-corelibs-perl libpod-latex-perl libpod-readme-perl libpython3-stdlib libpython3.4-minimal libpython3.4-stdlib libregexp-common-perl libseccomp2 libsoftware-license-perl libsub-exporter-perl libsub-install-perl libterm-ui-perl libtext-soundex-perl libtext-template-perl python3 python3-minimal python3.4 python3.4-minimal rename
   [JESSIE]: dpkg install-info libalgorithm-diff-xs-perl libc-bin libc-dev-bin libc6 libc6-dev libfile-fcntllock-perl libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblocale-gettext-perl libpipeline1 libselinux1 libtext-charwidth-perl libtext-iconv-perl libtirpc1 libuuid-perl lxc man-db nfs-common perl perl-base perl-modules
```

* Debian 7 Wheezy HOST (virtualbox-ose-guest)
```
   [WHEEZY/WHEEZY-BACKPORTS] libasound2 libasyncns0 libcaca0 libcurl3 libdbus-1-3 libdirectfb-1.2-9 libflac8 libgsoap4 libjpeg8 libjson-c2 libogg0 libpng12-0 libpulse0 libpython2.7 libsdl1.2debian libsndfile1 libts-0.0-0 libvncserver0 libvorbis0a libvorbisenc2 libvpx1 libx11-xcb1 libxcursor1 libxi6 libxtst6 tsconf virtualbox virtualbox-dkms
```

* Debian 8 Jessie HOST
```
   [JESSIE]: screen bridge-utils lxc
```

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
   * proxy_arp/ndp support (server mode)
   * dhcp/ra support (desktop mode)

* transparent network flow
   * if you run debian linux inside a virtualbox with an wireless lan bridge and the option "promiscuous mode: allow all" then the lxc-to-go "server" variant will also work!
      * (thanks to proxy_arp/ndp)

* wlan bridge support
   * add support (in server variant) for native debian linux (use in future the modified version)

usage:
```
   git clone https://github.com/plitc/lxc-to-go
   cd lxc-to-go/modification
   ./wlan_support.sh
   cd ..

   ./lxc-to-go_wlan.sh
```

* rp_filter enabled by default

* simple "template/flavor hooks" for general purposes

* provisioning
   * provisioning templates

```
   # ./lxc-to-go-template.sh
```

* /usr/sbin symbolic link support

```
   lxc-to-go
   lxc-to-go-provisioning
   lxc-to-go-template
   lxc-to-go_wlan
   lxc-to-go_wlan-provisioning
```

* LXC inside LXC
   * allow lxc-to-go to run within a container
   * works only with a debian 8 container and special permission settings:
      * step 1: copy your current kernel config (for example /boot/config-3.16.0-4-amd64) to your lxc-to-go container /boot directory
      * step 2: copy the /var/cache/lxc/debian/rootfs-wheezy-amd64 to your lxc-to-go/var/cache/lxc/debian directory
      * step 3: change the lxc-to-go container config, see below
```
### LXC inside LXC // ###

lxc.utsname=lxctogo

# vswitch0 / untagged
lxc.network.type=veth
lxc.network.link=vswitch0
lxc.network.name=eth0
lxc.network.hwaddr=aa:aa:aa:aa:aa:aa
lxc.network.veth.pair=lxctogo
lxc.network.flags=up

lxc.mount=/etc/lxc/fstab.empty
lxc.rootfs=/lxc-container/lxctogo

# mounts point
lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry = sysfs sys sysfs defaults  0 0

### LXC - lxctogo/systemd hacks // ###
lxc.autodev = 1
lxc.kmsg = 0
#
#!# lxc.cap.drop = sys_admin
#!# lxc.cap.drop = mknod
#!# lxc.cap.drop = audit_control
#!# lxc.cap.drop = audit_write
#!# lxc.cap.drop = setfcap
#!# lxc.cap.drop = setpcap
#!# lxc.cap.drop = sys_resource
#
lxc.cap.drop = sys_module
lxc.cap.drop = mac_admin
lxc.cap.drop = mac_override
lxc.cap.drop = sys_time
lxc.cap.drop = sys_boot
lxc.cap.drop = sys_pacct
lxc.cap.drop = sys_rawio
lxc.cap.drop = sys_tty_config
#
lxc.tty=99
lxc.pts = 1024
##/ lxc.mount.entry = /run/systemd/journal mnt/journal none bind,ro,create=dir 0 0
#### // LXC - lxctogo/systemd hacks ###

### // LXC inside LXC ###
```

Platform
========
* Linux
   * Debian 8 / Jessie (recommended)
   * Debian 7 / Wheezy

Usage
=====
```
    WARNING: lxc-to-go is experimental and its not ready for production. Do it at your own risk.

    # usage: ./lxc-to-go.sh { bootstrap | start | stop | create | delete | show }
```

Example
=======
* bootstrap
```
    # ./lxc-to-go.sh bootstrap

        Stage 1 finished. Please Reboot your System immediately! and continue the bootstrap

    # ./lxc-to-go.sh bootstrap

    ### lxc-attach -n managed (or screen attach) ###

    lxc-to-go bootstrap finished.
```

* start
```
    # ./lxc-to-go.sh start
    FOUND:
    test1 test2 test3 test4 test5 

    ... LXC Container (screen sessions): ...
        14608.test1     (04/22/15 10:19:39)     (Detached)
        14887.test2     (04/22/15 10:19:44)     (Detached)
        15147.test3     (04/22/15 10:19:49)     (Detached)
        15409.test4     (04/22/15 10:19:54)     (Detached)
        15671.test5     (04/22/15 10:19:59)     (Detached)

    lxc-to-go start finished.
```

* stop
```
    # ./lxc-to-go.sh stop 
    FOUND (active):
    test1 test2 test3 test4 test5 

    lxc-to-go stop finished.
```

* create
```
    # ./lxc-to-go.sh create
    Please enter the new LXC Container name:
    test

    Choose the LXC template:
    1) wheezy
    2) jessie
    1
    select: wheezy
    Created container test as copy of deb7template

    Do you wish to start this LXC Container: test ? (y/n) y

    ... starting screen session ...
        3898.test        (04/22/15 08:03:34)     (Detached)

    Do you wanna use 'flavor hooks' ? (y/n) y

    ... please wait 15 seconds ...


    <--- --- --- flavor hooks // --- --- --->
    example
    <--- --- --- // flavor hooks --- --- --->

    lxc-to-go create finished.
```

* delete
```
    # ./lxc-to-go.sh delete 
    test test1 test2 

    Please enter the LXC Container name to DESTROY:
    test

    ... shutdown & delete the lxc container ...

    lxc-to-go delete finished.
```

* provisioning
```
    # ./lxc-to-go_provisioning.sh -n test3 -t deb8 -h yes -p 60003 -s yes
    Created container test3 as copy of deb8template

    ... starting screen session ...
          6743.test3     (04/24/15 00:48:53)    (Detached)


    ... please wait 15 seconds ...


    <--- --- --- provisioning hooks // --- --- --->
    example
    <--- --- --- // provisioning hooks --- --- --->


    lxc-to-go provisioning finished.
```

* show
```
    # ./lxc-to-go.sh show
    NAME          STATE    IPV4                              IPV6                                    AUTOSTART  PID    MEMORY    RAM       SWAP
    ---------------------------------------------------------------------------------------------------------------------------------------------
    managed       RUNNING  192.168.253.254, 192.168.254.254  fd00:aaaa:253::254, fd00:aaaa:254::254  NO         1124   8.16MB    8.16MB    0.0MB
    test1         RUNNING  192.168.254.126                   fd00:aaaa:254:0:aaa:1                   NO         10639  3.7MB     3.68MB    0.02MB
    test2         RUNNING  192.168.254.125                   fd00:aaaa:254:0:aaa:2                   NO         8309   4.05MB    4.04MB    0.01MB
    test3         STOPPED  -                                 -                                       NO         -      -         -         -
```

Provisioning Template Support
=============================
* plain_provisioning (default)
* ![com.github.santex.flower](https://github.com/santex/flower)
   * (works with deb7/deb8 lxc)
* ![com.github.santex.ai-microstructure](https://github.com/santex/AI-MicroStructure)
   * (works only with deb7 lxc)
* ![com.gitlab.communityedition](https://about.gitlab.com/downloads/)
   * (works with deb7/deb8 lxc)
   * (on your clients: echo "ip HOSTNAME.privat.local" >> /etc/hosts)

Diagram
=======
* lxc-to-go LXC inside LXC Support (prototype > 0.31.5)
![lxc-to-go_schema](/content/lxc-to-go_inside_.jpg)

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
* 04.05.2015: [lxc-to-go < 0.26.5]: missing lxc debian wheezy template on debian jessie release HOST environment --- FIXED in [0.26.8]

* 27.04.2015: [lxc-to-go < 0.25]: multiple start of "start function" generating unnecessary firewall rules

* 23.04.2015: [lxc-to-go < 0.17.4]: "locales" package removed
```
  locale: Cannot set LC_CTYPE to default locale: No such file or directory
  locale: Cannot set LC_MESSAGES to default locale: No such file or directory
  locale: Cannot set LC_ALL to default locale: No such file or directory

  The following packages have unmet dependencies:
   locales : Depends: glibc-2.13-1
             Depends: debconf (>= 0.5) but it is not going to be installed or
                      debconf-2.0
  E: Unable to correct problems, you have held broken packages.
```

* 22.04.2015: [lxc-to-go < 0.17.1]: under circumstances can't load rc.local (firewall rules) after lxc 'managed' bootstrap --- FIXED in [0.19.1]

* 21.04.2015: [lxc-to-go < 0.14.1]: Starting VirtualBox AdditionsVBoxService: error: VbglR3Init failed with rc=VERR_FILE_NOT_FOUND failed!
```
   STRACE: open("/dev/vboxguest", O_RDWR|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```

* 21.04.2015: [lxc-to-go < 0.13.5]: add unnecessary kernel options on debian 7 wheezy for kernel 3.2 (not critical) --- FIXED in [0.19.1]

TODO
====
* 06.05.2015: ipv6 portforwarding

* 17.04.2015: useful ipv6 routing (ra/proxy_ndp) --- FIXED in [0.28.4]

* 16.04.2015: support for zfs/btrfs lxc-clone templates

