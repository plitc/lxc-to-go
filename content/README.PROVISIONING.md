# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

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

* [com.github.ether.etherpad-lite.dirtydb](https://github.com/ether/etherpad-lite)
   * (lxc-to-go-provisioning -n etherpad -t deb8 -h yes -p 9001 -s yes)
      * (works currently only with deb8 lxc)

* [com.github.ether.etherpad-lite.mariadb](https://github.com/ether/etherpad-lite)
   * (lxc-to-go-provisioning -n etherpad2 -t deb8 -h yes -p 9002 -s yes)
      * (works currently only with deb8 lxc)

* [com.github.ether.etherpad-lite.mariadb-utf8mb4](https://github.com/ether/etherpad-lite)
   * (lxc-to-go-provisioning -n etherpad3 -t deb8 -h yes -p 9003 -s yes)
      * (works currently only with deb8 lxc)
      * https://github.com/ether/etherpad-lite/wiki/How-to-use-Etherpad-Lite-with-MySQL

```
    ALTER DATABASE store CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
    USE store;
    ALTER TABLE store CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
```

* [org.samba.simple](https://www.samba.org)
   * (lxc-to-go-provisioning -n samba -t deb8 -h yes -p 135,136,137,138,139,445 -s yes)
      * (works currently only with deb8 lxc)

```
#/ * [org.samba.active-directory](https://www.samba.org)
#/ * (lxc-to-go-provisioning -n ads -t deb8 -h yes -p 53,88,135,136,137,138,139,389,445,464,636,1024,3268,3269 -s yes)
#/ * (works currently only with deb8 lxc)
```

* [com.github.letsencrypt](https://letsencrypt.org/)
   * (lxc-to-go-provisioning -n letsencrypt -t deb8 -h yes -p 80 -s yes)
      * (works currently only with deb8 lxc)

* [com.docker](https://docker.com/)
   * (lxc-to-go-provisioning -n docker -t deb8 -h yes -p 9999 -s yes)
      * (works currently only with deb8 lxc)
      * (Docker WebGUI: docker run -d -p 9999:9999 -v /var/run/docker.sock:/var/run/docker.sock dockerui/dockerui)

* [com.docker.lxcdriver](https://docker.com/)
   * (lxc-to-go-provisioning -n dockerlxc -t deb8 -h yes -p 9998 -s yes)
      * (works currently only with deb8 lxc)

* [com.docker.x11gui](https://docker.com/)
   * (lxc-to-go-provisioning -n dockerx11gui -t deb8 -h yes -p 9995 -s yes)
      * (works currently only with deb8 lxc)

