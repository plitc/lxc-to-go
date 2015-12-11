
Presentation
============
* [lxc-to-go presentation](https://plitc.github.io/lxc-to-go/presentation/)

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

Security Conditions
===================
```
   apt-get install sudo
   visudo
### INPUT // ###
   myusername ALL = (root) NOPASSWD: /usr/sbin/lxc-to-go
   myusername ALL = (root) NOPASSWD: /usr/sbin/lxc-to-go-template
   myusername ALL = (root) NOPASSWD: /usr/sbin/lxc-to-go-provisioning
### // INPUT ###
```

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

* Debian 9 Testing (Stretch/Sid) HOST

```
   [STRETCH]: screen bridge-utils lxc cgmanager
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

* /usr/sbin symbolic link support

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

Platform
========
* Linux (amd64 / i386 / powerpc)
   * Debian
      * 9 / Testing Stretch/Sid (recommended)
      * 8 / Jessie (recommended)
      * 7 / Wheezy
   * LMDE (Linux Mint Debian Edition)
      * 2 / Betsy
   * Ubuntu Desktop
      * 15.10 / Wily Werewolf
   * Ubuntu Server (lxc-to-go experimental support)
      * 15.10
   * Devuan Debian Jessie (System without Systemd)
      * Alpha 2

Usage
=====
```
    WARNING: lxc-to-go is experimental and its not ready for production. Do it at your own risk.

    # usage: ./lxc-to-go.sh { bootstrap | start | stop | shutdown | create | delete | show | login | lxc-in-lxc-webpanel }
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

* shutdown

```
    # ./lxc-to-go.sh shutdown


    lxc-to-go shutdown finished.
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

* login

```
    [DIALOG]
```

* lxc-in-lxc-webpanel

```
    LXC-Web-Panel:   http://192.168.253.254:5000
    Username:        admin
    Password:        admin
    default gateway: 192.168.252.254 (for the lxc-inside-lxc containers)
```

Provisioning Template Support
=============================

* plain.provisioning (default)
* plain.provisioning.x11gui
   * (lxc-to-go-provisioning -n x11 -t deb8 -h yes -p 60001 -s yes)
      * (works currently only with deb8 lxc)
* plain.provisioning_x11gui.browser
   * (with chromium, iceweasel & flashplugin-nonfree)
   * (lxc-to-go-provisioning -n x11browser -t deb8 -h yes -p 60002 -s yes)
      * (works currently only with deb8 lxc)
* [com.github.plitc.flower](https://github.com/plitc/flower)
   * (lxc-to-go-provisioning -n flower -t deb8 -h yes -p 2222 -s yes)
      * (works with deb7/deb8 lxc)
* [com.github.santex.flower](https://github.com/santex/flower)
   * (lxc-to-go-provisioning -n newflower -t deb8 -h yes -p 2222 -s yes)
      * (works currently only with deb8 lxc)
      * (X11 inside LXC: lxc-attach -n newflower -- chromium --no-sandbox)
* [com.github.santex.ai-microstructure](https://github.com/santex/AI-MicroStructure)
   * (lxc-to-go-provisioning -n micro -t deb7 -h yes -p 10001 -s yes)
      * (works currently only with deb7 lxc)
* [com.gitlab.communityedition](https://about.gitlab.com/downloads/)
   * (lxc-to-go-provisioning -n gitlab -t deb8 -h yes -p 80 -s yes)
      * (works with deb7/deb8 lxc)
      * (on your clients: echo "ip HOSTNAME.privat.local" >> /etc/hosts)
* [org.openwrt.freeradius.public](http://wiki.openwrt.org/doc/howto/wireless.security.8021x)
   * (lxc-to-go-provisioning -n radius -t deb8 -h yes -p 1812,1813,1814 -s yes)
      * (works currently only with deb8 lxc)
* [org.openwrt.freeradius.anonymous-eap-ttls](http://wiki.openwrt.org/doc/howto/wireless.security.8021x)
   * (lxc-to-go-provisioning -n radius -t deb8 -h yes -p 1645,1646,1647 -s yes)
   * !!! allow any radius login credentials !!!
      * (works currently only with deb8 lxc)
* [com.github.ether.etherpad-lite](https://github.com/ether/etherpad-lite)
   * (lxc-to-go-provisioning -n etherpad -t deb8 -h yes -p 9001 -s yes)
      * (works currently only with deb8 lxc)
* [org.samba.simple](https://www.samba.org)
   * (lxc-to-go-provisioning -n samba -t deb8 -h yes -p 135,136,137,138,139,445 -s yes)
      * (works currently only with deb8 lxc)
* [com.github.letsencrypt](https://letsencrypt.org/)
   * (lxc-to-go-provisioning -n letsencrypt -t deb8 -h yes -p 80 -s yes)
      * (works currently only with deb8 lxc)

```
#/ * [org.samba.active-directory](https://www.samba.org)
#/ * (lxc-to-go-provisioning -n ads -t deb8 -h yes -p 53,88,135,136,137,138,139,389,445,464,636,1024,3268,3269 -s yes)
#/ * (works currently only with deb8 lxc)
```

Diagram
=======
* lxc-to-go LXC inside LXC Support
  * (prototype > 0.31.5)
![lxc-to-go_inside](/content/lxc-to-go_inside_.jpg)

* lxc-to-go bootstrap
  * (prototype > 0.11)
![lxc-to-go_schema](/content/lxc-to-go_schema_.jpg)

* lxc-to-go for servers or mobile devices with wireless lan bridge
  * proxy mode (prototype > 0.9)
![lxc-to-go_servers](/content/lxc-to-go_servers_.jpg)

* lxc-to-go for mobile devices
  * bridge mode (prototype 0.6)
![lxc-to-go_desktop](/content/lxc-to-go_desktop_.jpg)

Screencast
==========
* github plitc lxc-to-go [VERSION: 07.08.2015]
   * a short introduction (bootstrap, start, stop, create, delete, shutdown, login)

[![github plitc lxc-to-go](https://img.youtube.com/vi/ITG8C9U3Q6E/0.jpg)](https://www.youtube.com/watch?v=ITG8C9U3Q6E)

* github plitc lxc-to-go webpanel [VERSION: 08.11.2015]
   * lxc-inside-lxc webpanel

[![github plitc lxc-to-go-webpanel](https://img.youtube.com/vi/zc0Mog-z4AQ/0.jpg)](https://www.youtube.com/watch?v=zc0Mog-z4AQ)

Errata
======
* 04.12.2015: [lxc-to-go < 0.40.0.0]: lxc-to-go "bootstrap" (proxy mode) on Ubuntu with double ip mapping (phy./bridge) disturbs the routing --- OPEN again

```
  WORKAROUND:

  ~# ./lxc-to-go.sh bootstrap
     abort: Ctrl-C

  ~# ip addr flush dev vswitch0
  ~# ./lxc-to-go.sh bootstrap
```

* 22.11.2015: [lxc-to-go < 0.39.3.5]: lxc-to-go on Ubuntu: lxc-clone failed (empty deb7/deb8 templates) --- OPEN

* 22.11.2015: [lxc-to-go < 0.39.2.7]: lxc-to-go doesn't work with apparmor on Ubuntu --- WORKAROUND: disable apparmor in [0.39.2.8]

* 21.11.2015: [lxc-to-go < 0.39.2.3]: lxc-to-go "bootstrap" (proxy mode) on Ubuntu with double ip mapping (phy./bridge) disturbs the routing --- FIXED in [0.39.2.4]

* 21.11.2015: [lxc-to-go < 0.39.0.7]: lxc-to-go "bootstrap" failed when the choosed interface havn't got the default gateway route --- OPEN

```
  WORKAROUND:

  route del default
  ip route replace default via "MY_GATEWAY_IP" dev "MY_NEW_INTERFACE"

  ./lxc-to-go.sh bootstrap
     Choose your Interface: (eth0/wlan0) ? "MY_NEW_INTERFACE"
```

* 13.11.2015: [lxc-to-go < 0.38.9.9]: lxc-to-go "proxy mode" issue with [easy_ipsec](https://github.com/plitc/easy_ipsec) --- OPEN

* 09.11.2015: [lxc-to-go < 0.38.8.8]: lxc-to-go-provisioning can't set host iptables rules --- OPEN

* 09.11.2015: [lxc-to-go < 0.38.7.7]: Cgroup memory controller: missing (but works on debian 9 (testing/stretch) with kernel 4.2) --- OPEN

* 30.06.2015: [lxc-to-go < 0.26.5]: issue with [ulatencyd](https://packages.debian.org/stretch/ulatencyd) --- OPEN

* 04.05.2015: [lxc-to-go < 0.26.5]: missing lxc debian wheezy template on debian jessie release HOST environment --- FIXED in [0.26.8]

* 27.04.2015: [lxc-to-go < 0.25]: multiple start of "start function" generating unnecessary firewall rules --- OPEN

* 23.04.2015: [lxc-to-go < 0.17.4]: "locales" package removed --- OPEN

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

* 21.04.2015: [lxc-to-go < 0.14.1]: Starting VirtualBox AdditionsVBoxService: error: VbglR3Init failed with rc=VERR_FILE_NOT_FOUND failed! --- OPEN

```
   STRACE: open("/dev/vboxguest", O_RDWR|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```

* 21.04.2015: [lxc-to-go < 0.13.5]: add unnecessary kernel options on debian 7 wheezy for kernel 3.2 (not critical) --- FIXED in [0.19.1]

TODO
====
* 02.12.2015: unprivileged containers support --- OPEN

* 27.11.2015: source based routing support --- OPEN

* 08.11.2015: deb9 testing template --- OPEN

* 06.05.2015: ipv6 portforwarding --- FIXED in [0.40.3.6]

* 17.04.2015: useful ipv6 routing (ra/proxy_ndp) --- FIXED in [0.28.4] --- FIXED again in [0.39.9.7]

* 16.04.2015: support for zfs/btrfs lxc-clone templates --- OPEN

