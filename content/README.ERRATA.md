# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

Errata
======
* 11.12.2016: [lxc-to-go 0.42.0.4]: Default Debian (Testing) Kernel 4.8 issue - (need bootoption: vsyscall=emulate) --- FIXED in [Version: 0.42.0.8.travis32]
-> https://github.com/docker/docker/issues/28705
```
Dec 10 14:49:41 root6 kernel: [  135.380512] update-locale[1071] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7fff7acc87f8 ax:ffffffffff600400 si:0 di:846560
Dec 10 14:49:41 root6 kernel: [  135.380602] update-locale[1071]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007fff7acc87f8 error 15
Dec 10 14:49:41 root6 kernel: [  135.381826] update-rc.d[1072] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffdcee59418 ax:ffffffffff600400 si:0 di:1152560
Dec 10 14:49:41 root6 kernel: [  135.381894] update-rc.d[1072]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffdcee59418 error 15
Dec 10 14:49:41 root6 kernel: [  135.383069] update-rc.d[1073] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffffb219368 ax:ffffffffff600400 si:0 di:f1c560
Dec 10 14:49:41 root6 kernel: [  135.383137] update-rc.d[1073]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffffb219368 error 15
Dec 10 14:49:41 root6 kernel: [  135.384407] update-rc.d[1074] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffce797dd28 ax:ffffffffff600400 si:0 di:1184560
Dec 10 14:49:41 root6 kernel: [  135.384472] update-rc.d[1074]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffce797dd28 error 15
Dec 10 14:49:41 root6 kernel: [  135.385520] update-rc.d[1075] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffe21cb9338 ax:ffffffffff600400 si:0 di:1d15560
Dec 10 14:49:41 root6 kernel: [  135.385587] update-rc.d[1075]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffe21cb9338 error 15
Dec 10 14:49:41 root6 kernel: [  135.388736] frontend[1079] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffefda08cc8 ax:ffffffffff600400 si:0 di:14f4560
Dec 10 14:49:41 root6 kernel: [  135.388802] frontend[1079]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffefda08cc8 error 15
Dec 10 14:49:41 root6 kernel: [  135.392871] dpkg-reconfigur[1084] vsyscall attempted with vsyscall=none ip:ffffffffff600400 cs:33 sp:7ffc032f8368 ax:ffffffffff600400 si:0 di:8de560
Dec 10 14:49:41 root6 kernel: [  135.392941] dpkg-reconfigur[1084]: segfault at ffffffffff600400 ip ffffffffff600400 sp 00007ffc032f8368 error 15
Dec 11 14:20:41 root6 kernel: [    0.000000] Linux version 4.8.0-1-amd64 (debian-kernel@lists.debian.org) (gcc version 5.4.1 20161019 (Debian 5.4.1-3) ) #1 SMP Debian 4.8.7-1 (2016-11-13)
Dec 11 14:20:41 root6 kernel: [    0.000000] Command line: BOOT_IMAGE=/vmlinuz-4.8.0-1-amd64 root=/dev/mapper/root6-system ro cgroup_enable=memory swapaccount=1
```

```
Note : Before booting a new kernel, you can check its configuration
usage : CONFIG=/path/to/config /usr/bin/lxc-checkconfig

[  OK  ] 'optional: wheezy kernel upgrade'
[  OK  ] 'optional: wheezy lxc upgrade'
[  OK  ] 'grub configcheck'
[  OK  ] 'optional: powerpc / travis-ci environment configcheck'
[  OK  ] 'modprobe: iptables/nf_nat'
[  OK  ] 'prepare bridge zones - stage 1'
[  OK  ] 'prepare bridge zones - stage 2'
[  OK  ] 'prepare bridge zones - stage 3'
[ERROR] previous managed lxc container bootstrap goes wrong

Do you wish to remove and cleanup the corrupt lxc-to-go environment and start again ? (y/n) y
managed is not running
Destroyed container managed
Container is not defined
Container is not defined

[  OK  ] 'lxc: managed bootstrap - stage 1'
Create subvolume '/var/lib/lxc/managed'
[  OK  ] 'create new btrfs lxc: managed subvolume'
debootstrap ist /usr/sbin/debootstrap
Checking cache download in /var/cache/lxc/debian/rootfs-wheezy-amd64 ...
Copying rootfs to /var/lib/lxc/managed/rootfs...Generating locales (this might take a while)...
de_DE.UTF-8... done
de_DE.UTF-8... done
Generation complete.
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1129 Speicherzugriffsfehler  chroot "$rootfs" update-locale LANG="$LANG"
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1130 Speicherzugriffsfehler  chroot "$rootfs" /usr/sbin/update-rc.d -f checkroot.sh disable
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1131 Speicherzugriffsfehler  chroot "$rootfs" /usr/sbin/update-rc.d -f umountfs disable
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1132 Speicherzugriffsfehler  chroot "$rootfs" /usr/sbin/update-rc.d -f hwclock.sh disable
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1133 Speicherzugriffsfehler  chroot "$rootfs" /usr/sbin/update-rc.d -f hwclockfirst.sh disable
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1137 Speicherzugriffsfehler  DPKG_MAINTSCRIPT_PACKAGE=openssh DPKG_MAINTSCRIPT_NAME=postinst chroot "$rootfs" /var/lib/dpkg/info/openssh-server.postinst configure
sed: kann /var/lib/lxc/managed/rootfs/etc/ssh/ssh_host_*.pub nicht lesen: Datei oder Verzeichnis nicht gefunden
/usr/share/lxc/templates/lxc-debian-wheezy: Zeile 45:  1142 Speicherzugriffsfehler  chroot "$rootfs" dpkg-reconfigure -f noninteractive tzdata
[  OK  ] 'lxc: managed bootstrap - stage 2'
[  OK  ] 'configure host sysctl'
[  OK  ] 'optional: fixes for ubuntu'

ERROR: target path already exists: /var/lib/lxc/deb7template
[FAILED] 'create new btrfs lxc: deb7template subvolume'
./lxc-to-go.sh: 2054: ./lxc-to-go.sh: lxc-clone: not found
^C

root@root6:/github/lxc-to-go#
```

* 19.12.2015: [lxc-to-go < 0.40.8.8]: lxc-to-go start / delete [FAILED] 'lxc: set up nat rules' --- OPEN

* 12.12.2015: [lxc-to-go < 0.40.8.8]: lxc-to-go start / delete [FAILED] 'lxc: set up nat rules' --- OPEN

```
  Another app is currently holding the xtables lock. Perhaps you want to use the -w option?
  [FAILED] 'lxc: set up nat rules'

  WORKAROUND:

  ~# ./lxc-to-go.sh start
```

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

* 13.11.2015: [lxc-to-go < 0.41.2.7.travis29]: lxc-to-go X11 Video & Audio Support: Unix Domain Socket sharing works only in the same Environment (HOST: deb8 - LXC: deb8) --- OPEN

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

