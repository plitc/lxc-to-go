# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

Errata
======
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

