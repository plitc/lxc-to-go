#!/bin/sh

### LICENSE - (BSD 2-Clause) // ###
#
# Copyright (c) 2015, Daniel Plominski (Plominski IT Consulting)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE - (BSD 2-Clause) ###

### ### ### PLITC // ### ### ###

### stage0 // ###
DEBIAN=$(grep -s "ID" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep -s "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
MYNAME=$(whoami)
### // stage0 ###

case "$1" in
'bootstrap')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

mkdir -p /etc/lxc-to-go
CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
if [ -z "$CHECKENVIRONMENT" ]; then
         read -p "Choose your Environment: (desktop/server) ? " ENVIRONMENTVALUE
         if [ "$ENVIRONMENTVALUE" = "desktop" ]; then
            echo "ENVIRONMENT=desktop" > /etc/lxc-to-go/lxc-to-go.conf
         fi
         if [ "$ENVIRONMENTVALUE" = "server" ]; then
            echo "ENVIRONMENT=server" > /etc/lxc-to-go/lxc-to-go.conf
         fi
         if [ -z "$ENVIRONMENTVALUE" ]; then
            echo "[ERROR] choose an environment"
            exit 1
         fi
fi
GETENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')

SCREEN=$(/usr/bin/which screen)
if [ -z "$SCREEN" ]; then
    echo "<--- --- --->"
    echo "need screen"
    echo "<--- --- --->"
    apt-get update
    apt-get -y install screen
    echo "<--- --- --->"
fi

LXC=$(/usr/bin/dpkg -l | grep lxc | awk '{print $2}')
if [ -z "$LXC" ]; then
    echo "<--- --- --->"
    echo "need lxc"
    echo "<--- --- --->"
    apt-get update
    apt-get -y install lxc
    echo "<--- --- --->"
fi

BRIDGEUTILS=$(/usr/bin/dpkg -l | grep bridge-utils | awk '{print $2}')
if [ -z "$BRIDGEUTILS" ]; then
    echo "<--- --- --->"
    echo "need bridge-utils"
    echo "<--- --- --->"
    apt-get update
    apt-get -y install bridge-utils
    echo "<--- --- --->"
fi

NETTOOLS=$(/usr/bin/dpkg -l | grep net-tools | awk '{print $2}')
if [ -z "$NETTOOLS" ]; then
    echo "<--- --- --->"
    echo "need net-tools"
    echo "<--- --- --->"
    apt-get update
    apt-get -y install net-tools
    echo "<--- --- --->"
fi

sleep 1
    : # dummy
CHECKCGROUP=$(mount | grep -c "cgroup")
if [ "$CHECKCGROUP" = "1" ]; then
    : # dummy
else
    mount cgroup -t cgroup /sys/fs/cgroup
fi
    lxc-checkconfig
    if [ $? -eq 0 ]
    then
       : # dummy
    else
       echo "[ERROR] lxc-checkconfig failed!"
       exit 1
    fi
sleep 1

### Wheezy KERNEL UPGRADE // ###
if [ "$DEBVERSION" = "7" ]; then
   CHECKDEB7KERNEL=$(cat /proc/sys/kernel/osrelease | grep -c "3.2")
   if [ "$CHECKDEB7KERNEL" = "1" ]; then
      CHECKDEB7KERNEL316=$(dpkg -l | grep -c "linux-headers-3.16")
      if [ "$CHECKDEB7KERNEL316" = "0" ]; then
         CHECKDEB7BACKPORTS=$(grep -r "wheezy-backports" /etc/apt/ | grep -c "wheezy-backports")
            if [ "$CHECKDEB7BACKPORTS" = "0" ]; then
               echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/wheezy-backports.list
               echo "deb-src http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list.d/wheezy-backports.list
            fi
            apt-get -y autoclean
            apt-get -y clean
            apt-get -y update
            CHECKDEB7ARCH=$(arch)
            if [ "$CHECKDEB7ARCH" = "686" ]; then
               apt-get -y install initramfs-tools=0.115*
               apt-get -y install linux-image-3.16.0-0.bpo.4-686-pae linux-headers-3.16.0-0.bpo.4-686-pae
               apt-get -y install firmware-linux-nonfree
               CHECKDEB7VBOX=$(dpkg -l | grep -c "virtualbox-guest-dkms")
               if [ "$CHECKDEB7VBOX" = "1" ]; then
                  apt-get -y install build-essential module-assistant
                  m-a prepare
                  apt-get -y install --reinstall virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11
                  #/ apt-get -y install --reinstall virtualbox-guest-dkms
                  apt-get -y install virtualbox-dkms -t wheezy-backports --no-install-recommends
               fi
            fi
            if [ "$CHECKDEB7ARCH" = "x86_64" ]; then
               apt-get -y install initramfs-tools=0.115*
               apt-get -y install linux-image-3.16.0-0.bpo.4-amd64 linux-headers-3.16.0-0.bpo.4-amd64
               apt-get -y install firmware-linux-nonfree
               CHECKDEB7VBOX=$(dpkg -l | grep -c "virtualbox-guest-dkms")
               if [ "$CHECKDEB7VBOX" = "1" ]; then
                  apt-get -y install build-essential module-assistant
                  m-a prepare
                  apt-get -y install --reinstall virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11
                  #/ apt-get -y install --reinstall virtualbox-guest-dkms
                  apt-get -y install virtualbox-dkms -t wheezy-backports --no-install-recommends
               fi
            fi

      fi
   fi
fi
### // Wheezy KERNEL UPGRADE ###

### Wheezy - Jessie LXC // ###
if [ "$DEBVERSION" = "7" ]; then
   CHECKDEB7JESSIELXC=$(grep -r "jessie" /etc/apt/sources.list* | grep -c "jessie")
   if [ "$CHECKDEB7JESSIELXC" = "0" ]; then

/bin/cat << CHECKDEB7JESSIELXCFILE > /etc/apt/sources.list.d/jessie.list
### ### ### lxc-to-go // ### ### ###
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free

deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free

deb http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
deb-src http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
### ### ### // lxc-to-go  ### ### ###
# EOF

### deb http://ftp.de.debian.org/debian sid main
CHECKDEB7JESSIELXCFILE

   apt-get -y autoclean
   apt-get -y clean
   apt-get -y update
      apt-get -y install --reinstall -t jessie lxc
   fi
fi
### // Wheezy - Jessie LXC ###

## modify grub

CHECKGRUB1=$(grep "GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "cgroup_enable=memory" | grep -c "swapaccount=1")
if [ "$CHECKGRUB1" = "1" ]; then
    : # dummy
else
    cp -prfv /etc/default/grub /etc/default/grub_BACKUP_lxctogo
    sed -i '/GRUB_CMDLINE_LINUX=/s/.$//' /etc/default/grub
    sed -i '/GRUB_CMDLINE_LINUX=/s/$/ cgroup_enable=memory swapaccount=1"/' /etc/default/grub

   ### grub update

   : # dummy
   sleep 2
   grub-mkconfig
   : # dummy
   sleep 2
   update-grub
   if [ "$?" != "0" ]; then
      : # dummy
      sleep 5
      echo "[ERROR] something goes wrong let's restore the old configuration!" 1>&2
      cp -prfv /etc/default/grub_BACKUP_lxctogo /etc/default/grub
      : # dummy
      sleep 2
      grub-mkconfig
      : # dummy
      sleep 2
      update-grub
      exit 1
   fi
   : # dummy
   echo "" # dummy
   printf "\033[1;31mStage 1 finished. Please Reboot your System immediately! and continue the bootstrap\033[0m\n"
   exit 0
fi

CHECKGRUB2=$(grep "cgroup_enable=memory" /proc/cmdline | grep -c "swapaccount=1")
if [ "$CHECKGRUB2" = "1" ]; then
   : # dummy
else
   : # dummy
   echo "" # dummy
   printf "\033[1;31mStage 1 finished. Please Reboot your System immediately! and continue the bootstrap\033[0m\n"
   exit 0
fi

### ### ###

### check ip_tables/ip6_tables kernel module

CHECKIPTABLES=$(lsmod | awk '{print $1}' | grep -c "ip_tables")
if [ "$CHECKIPTABLES" = "1" ]; then
    : # dummy
else
    modprobe ip_tables
fi

CHECKIP6TABLES=$(lsmod | awk '{print $1}' | grep -c "ip6_tables")
if [ "$CHECKIP6TABLES" = "1" ]; then
    : # dummy
else
    modprobe ip6_tables
fi

### ### ###

CREATEBRIDGE0=$(ip a | grep -c "vswitch0:")
if [ "$CREATEBRIDGE0" = "1" ]; then
    : # dummy
else
   brctl addbr vswitch0

   #/ if [ "$GETENVIRONMENT" = "desktop" ]; then
   #/ ip link add dummy0 type dummy >/dev/null 2>&1
   #/ brctl addif vswitch0 dummy0
   #/ fi

   UDEVNET="/etc/udev/rules.d/70-persistent-net.rules"
   if [ -e "$UDEVNET" ]; then
      GETBRIDGEPORT0=$(grep -s 'SUBSYSTEM=="net"' /etc/udev/rules.d/70-persistent-net.rules | grep "eth" | head -n 1 | tr ' ' '\n' | grep "NAME" | sed 's/NAME="//' | sed 's/"//')
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      brctl addif vswitch0 "$GETBRIDGEPORT0"
   fi
      sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".forwarding=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf."$GETBRIDGEPORT0".forwarding=1 >/dev/null 2>&1
   if [ "$GETENVIRONMENT" = "server" ]; then
   ### Proxy_ARP/NDP // ###
      sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".proxy_arp=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf."$GETBRIDGEPORT0".proxy_ndp=1 >/dev/null 2>&1
   ### // Proxy_ARP/NDP ###
   fi
   else
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      brctl addif vswitch0 eth0
   fi
      sysctl -w net.ipv4.conf.eth0.forwarding=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.eth0.forwarding=1 >/dev/null 2>&1
   if [ "$GETENVIRONMENT" = "server" ]; then
   ### Proxy_ARP/NDP // ###
      sysctl -w net.ipv4.conf.eth0.proxy_arp=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.eth0.proxy_ndp=1 >/dev/null 2>&1
   ### // Proxy_ARP/NDP ###
   fi
   fi
      sysctl -w net.ipv4.conf.vswitch0.forwarding=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.vswitch0.forwarding=1 >/dev/null 2>&1
   if [ "$GETENVIRONMENT" = "server" ]; then
   ### Proxy_ARP/NDP // ###
      sysctl -w net.ipv4.conf.vswitch0.proxy_arp=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.vswitch0.proxy_ndp=1 >/dev/null 2>&1
   ### // Proxy_ARP/NDP ###
   ### NAT // ###
      iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      #/ iptables -A FORWARD -i vswitch0 -j ACCEPT
      #/ sysctl -w net.ipv4.conf.all.forwarding=1 >/dev/null 2>&1
      ### # EXAMPLE #/ lxc1
      ### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10001 -j DNAT --to-destination 192.168.253.254:10001
      ### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10001 -j DNAT --to-destination 192.168.253.254:10001
   ### // NAT ###
   fi
###
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      : # dummy
      dhclient vswitch0
   fi
   if [ "$GETENVIRONMENT" = "server" ]; then
      : # dummy
### ### ###
##/ GETIPV4DEFAULTGATEWAY=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}')
netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | xargs -L1 -I {} echo "IPV4DEFAULTGATEWAY={}" > /tmp/lxc-to-go_IPV4GATEWAY.log
chmod 0700 /tmp/lxc-to-go_IPV4GATEWAY.log
#/    GETIPV4DEFAULTGATEWAYVALUE=$(grep -s "IPV4DEFAULTGATEWAY" /tmp/lxc-to-go_IPV4GATEWAY.log | sed 's/IPV4DEFAULTGATEWAY=//')
   if [ -e "$UDEVNET" ]; then
      GETIPV4UDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNETUDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -n 1 | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ifconfig vswitch0 inet "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV"
###/ip addr flush eth0
#/    ip addr del "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV" dev "$GETBRIDGEPORT0"
#/    route del default >/dev/null 2>&1
#/    route add default gw "$GETIPV4DEFAULTGATEWAYVALUE" dev vswitch0
   if [ "$GETENVIRONMENT" = "server" ]; then
      ip addr add 192.168.253.253/24 dev vswitch0
   fi
### fix //
CHECKGETIPV4DEFAULTGATEWAY1=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
if [ "$CHECKGETIPV4DEFAULTGATEWAY1" = "2" ]; then
   route del default
fi
### // fix
   else
      GETIPV4=$(ifconfig eth0 | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNET=$(ifconfig eth0 | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -n 1 | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ifconfig vswitch0 inet "$GETIPV4"/"$GETIPV4SUBNET"
###/ip addr flush eth0
#/    ip addr del "$GETIPV4"/"$GETIPV4SUBNET" dev eth0
#/    route del default >/dev/null 2>&1
#/    route add default gw "$GETIPV4DEFAULTGATEWAYVALUE" dev vswitch0
   if [ "$GETENVIRONMENT" = "server" ]; then
      ip addr add 192.168.253.253/24 dev vswitch0
   fi
### fix //
CHECKGETIPV4DEFAULTGATEWAY2=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
if [ "$CHECKGETIPV4DEFAULTGATEWAY2" = "2" ]; then
   route del default
fi
### // fix
   fi
### ### ###
   fi
###
fi

### ### ###
sleep 1; : # dummy
### ### ###

CHECKLXCMANAGED=$(lxc-ls | grep -c "managed")
if [ "$CHECKLXCMANAGED" = "1" ]; then
    : # dummy
else
   lxc-create -n managed -t debian
   if [ "$?" != "0" ]; then
      : # dummy
      echo '[ERROR] create "managed" lxc container failed'
      : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-destroy -n managed
         fi
      exit 1
   fi
fi

### ### ###
#/ sleep 1; : # dummy
### ### ###

CREATEBRIDGE1=$(ip a | grep -c "vswitch1:")
if [ "$CREATEBRIDGE1" = "1" ]; then
    : # dummy
else
   brctl addbr vswitch1
   sysctl -w net.ipv4.conf.vswitch1.forwarding=1 >/dev/null 2>&1
   sysctl -w net.ipv6.conf.vswitch1.forwarding=1 >/dev/null 2>&1
fi

### ### ###
#/ sleep 1; : # dummy
### ### ###

touch /etc/lxc/fstab.empty

LXCCONFIGFILEMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/config | awk '{print $4}' | head -n 1)
if [ X"$LXCCONFIGFILEMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      : # dummy
/bin/cat << LXCCONFIGMANAGED1 > /var/lib/lxc/managed/config
### ### ### lxc-to-go // ### ### ###

lxc.utsname=managed

# vswitch0 / untagged
lxc.network.type=veth
lxc.network.link=vswitch0
lxc.network.name=eth0
lxc.network.hwaddr=aa:bb:c0:0c:bb:aa
lxc.network.veth.pair=managed
lxc.network.flags=up

# vswitch1 / intern
lxc.network.type=veth
lxc.network.link=vswitch1
lxc.network.name=eth1
lxc.network.veth.pair=managed1
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.254.254/24
#/ lxc.network.ipv4.gateway = auto
lxc.network.ipv6 = fd00:aaaa:0254::254/64
###

lxc.mount=/etc/lxc/fstab.empty
lxc.rootfs=/var/lib/lxc/managed/rootfs

# mounts point
lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry = sysfs sys sysfs defaults  0 0

#/ lxc.cgroup.memory.limit_in_bytes=268435456
#/ lxc.cgroup.memory.memsw.limit_in_bytes=268435456

### default ### lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config
#/ lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config

#
### LXC - jessie/systemd hacks // ###
lxc.autodev = 1
lxc.kmsg = 0

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

lxc.tty=2
lxc.pts = 1024
#/ lxc.mount.entry = /run/systemd/journal mnt/journal none bind,ro,create=dir 0 0
### // LXC - jessie/systemd hacks ###
#

lxc.cgroup.devices.deny = a
# tty
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# console
lxc.cgroup.devices.allow = c 5:1 rwm
# ptmx
lxc.cgroup.devices.allow = c 5:2 rwm
# pts/*
lxc.cgroup.devices.allow = c 136:* rwm
# null
lxc.cgroup.devices.allow = c 1:3 rwm
# zero
lxc.cgroup.devices.allow = c 1:5 rwm
# full
lxc.cgroup.devices.allow = c 1:7 rwm
# random
lxc.cgroup.devices.allow = c 1:8 rwm
# urandom
lxc.cgroup.devices.allow = c 1:9 rwm
# fuse
lxc.cgroup.devices.allow = c 10:229 rwm
# tun
lxc.cgroup.devices.allow = c 10:200 rwm

### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGED1
### ### ###
#
#/ if [ "$DEBVERSION" = "7" ]; then
#/    sed -i '/lxc.autodev/d' /var/lib/lxc/managed/config
#/    sed -i '/lxc.kmsg/d' /var/lib/lxc/managed/config
#/ fi
#
### randomized MAC address // ###
RANDOM1=$(shuf -i 10-99 -n 1)
RANDOM2=$(shuf -i 10-99 -n 1)
sed -i 's/aa:bb:c0:0c:bb:aa/aa:bb:'"$RANDOM1"':'"$RANDOM2"':bb:aa/' /var/lib/lxc/managed/config
### randomized MAC address // ###
#
### ### ###
/bin/cat << CHECKMANAGEDNETFILE1 > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
iface eth0 inet6 auto

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE1
### ### ###
#
### randomized MAC address // ###

### randomized MAC address // ###
   fi
   if [ "$GETENVIRONMENT" = "server" ]; then
      : # dummy
/bin/cat << LXCCONFIGMANAGED2 > /var/lib/lxc/managed/config
### ### ### lxc-to-go // ### ### ###

lxc.utsname=managed

# vswitch0 / untagged
lxc.network.type=veth
lxc.network.link=vswitch0
lxc.network.name=eth0
lxc.network.hwaddr=aa:bb:c0:0c:bb:aa
lxc.network.veth.pair=managed
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.253.254/24
lxc.network.ipv4.gateway = 192.168.253.253
lxc.network.ipv6 = fd00:aaaa:0253::254/64
###

# vswitch1 / intern
lxc.network.type=veth
lxc.network.link=vswitch1
lxc.network.name=eth1
lxc.network.veth.pair=managed1
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.254.254/24
#/ lxc.network.ipv4.gateway = auto
lxc.network.ipv6 = fd00:aaaa:0254::254/64
###

lxc.mount=/etc/lxc/fstab.empty
lxc.rootfs=/var/lib/lxc/managed/rootfs

# mounts point
lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry = sysfs sys sysfs defaults  0 0

#/ lxc.cgroup.memory.limit_in_bytes=268435456
#/ lxc.cgroup.memory.memsw.limit_in_bytes=268435456

### default ### lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config
#/ lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config

#
### LXC - jessie/systemd hacks // ###
lxc.autodev = 1
lxc.kmsg = 0

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

lxc.tty=2
lxc.pts = 1024
#/ lxc.mount.entry = /run/systemd/journal mnt/journal none bind,ro,create=dir 0 0
### // LXC - jessie/systemd hacks ###
#

lxc.cgroup.devices.deny = a
# tty
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# console
lxc.cgroup.devices.allow = c 5:1 rwm
# ptmx
lxc.cgroup.devices.allow = c 5:2 rwm
# pts/*
lxc.cgroup.devices.allow = c 136:* rwm
# null
lxc.cgroup.devices.allow = c 1:3 rwm
# zero
lxc.cgroup.devices.allow = c 1:5 rwm
# full
lxc.cgroup.devices.allow = c 1:7 rwm
# random
lxc.cgroup.devices.allow = c 1:8 rwm
# urandom
lxc.cgroup.devices.allow = c 1:9 rwm
# fuse
lxc.cgroup.devices.allow = c 10:229 rwm
# tun
lxc.cgroup.devices.allow = c 10:200 rwm

### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGED2
### ### ###
/bin/cat << LXCCONFIGMANAGEDRESOLV > /var/lib/lxc/managed/rootfs/etc/resolv.conf
### ### ### lxc-to-go // ### ### ###
domain privat.local
search privat.local
nameserver 74.82.42.42
### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGEDRESOLV
### ### ###
#
#/ if [ "$DEBVERSION" = "7" ]; then
#/    sed -i '/lxc.autodev/d' /var/lib/lxc/managed/config
#/    sed -i '/lxc.kmsg/d' /var/lib/lxc/managed/config
#/ fi
#
### ### ###
/bin/cat << CHECKMANAGEDNETFILE2 > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
iface eth0 inet6 manual

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE2
### ### ###
   fi
fi
### ### ###
CHECKTEMPLATEDEB7=$(lxc-ls | grep -c "deb7template")
if [ "$CHECKTEMPLATEDEB7" = "1" ]; then
   : # dummy
else
   echo "" # dummy
if [ "$DEBVERSION" = "7" ]; then
   lxc-clone -o managed -n deb7template
else
   lxc-clone -M -B dir -o managed -n deb7template
fi
### ### ###
sed -i '/lxc.network.ipv4/d' /var/lib/lxc/deb7template/config
sed -i '/lxc.network.ipv6/d' /var/lib/lxc/deb7template/config
sed -i '0,/lxc.network.type = veth/s/lxc.network.type = veth//' /var/lib/lxc/deb7template/config
sed -i '0,/lxc.network.flags = up/s/lxc.network.flags = up//' /var/lib/lxc/deb7template/config
sed -i '0,/lxc.network.link = vswitch0/s/lxc.network.link = vswitch0//' /var/lib/lxc/deb7template/config
sed -i '0,/lxc.network.name = eth0/s/lxc.network.name = eth0//' /var/lib/lxc/deb7template/config
sed -i '0,/lxc.network.veth.pair = managed/s/lxc.network.veth.pair = managed//' /var/lib/lxc/deb7template/config
#/ sed -i '0,/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa/s/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa//' /var/lib/lxc/deb7template/config
sed -i '/lxc.network.hwaddr/d' /var/lib/lxc/deb7template/config
sed -i 's/managed1/deb7temp/g' /var/lib/lxc/deb7template/config
sed -i '/^\s*$/d' /var/lib/lxc/deb7template/config
### ### ###
#
#/ if [ "$DEBVERSION" = "7" ]; then
#/    sed -i '/lxc.autodev/d' /var/lib/lxc/deb7template/config
#/    sed -i '/lxc.kmsg/d' /var/lib/lxc/deb7template/config
#/ fi
#
### ### ###
echo "" # dummy
   ./hook_deb7.sh
echo "" # dummy
### ### ###
fi
### ### ###

CHECKMANAGED1STATUS=$(screen -list | grep "managed" | awk '{print $1}')

if [ "$DEBVERSION" = "7" ]; then
CHECKMANAGED1=$(lxc-ls --active | grep -c "managed")
#/ CHECKMANAGED1=$(lxc-list | sed -e '/FROZEN/,+99d' | grep -c "managed") # lxc 0.8
if [ "$CHECKMANAGED1" = "1" ]; then
   echo "... LXC Container (screen session: $CHECKMANAGED1STATUS): always running ..."
else
   echo "... LXC Container (screen session): managed starting ..."
   screen -d -m -S managed -- lxc-start -n managed
   sleep 1
   screen -list | grep "managed"
   ### ### ###
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      : # dummy
      echo "" # dummy
      echo "... please wait 30 seconds ..."
      sleep 30
      echo "" # dummy
      : # dummy
   fi
   if [ "$GETENVIRONMENT" = "server" ]; then
      : # dummy
      echo "" # dummy
      echo "... please wait 15 seconds ..."
      sleep 15
      echo "" # dummy
      : # dummy
   fi
   ### ### ###
fi
fi

if [ "$DEBVERSION" = "8" ]; then
CHECKMANAGED2=$(lxc-ls --active | grep -c "managed")
if [ "$CHECKMANAGED2" = "1" ]; then
   echo "... LXC Container (screen session: $CHECKMANAGED1STATUS): always running ..."
else
   echo "... LXC Container (screen session): managed starting ..."
   screen -d -m -S managed -- lxc-start -n managed
   sleep 1
   screen -list | grep "managed"
   ### ### ###
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      : # dummy
      echo "" # dummy
      echo "... please wait 30 seconds ..."
      sleep 30
      echo "" # dummy
      : # dummy
   fi
   if [ "$GETENVIRONMENT" = "server" ]; then
      : # dummy
      echo "" # dummy
      echo "... please wait 15 seconds ..."
      sleep 15
      echo "" # dummy
      : # dummy
   fi
   ### ### ###
fi
fi

CHECKUPDATELIST1=$(grep "jessie" /var/lib/lxc/managed/rootfs/etc/apt/sources.list | head -n 1 | grep -c "jessie")
if [ "$CHECKUPDATELIST1" = "1" ]; then
   : # dummy
else
   /bin/cat << CHECKUPDATELIST1IN > /var/lib/lxc/managed/rootfs/etc/apt/sources.list
### ### ### PLITC ### ### ###
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free

deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free

deb http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
deb-src http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
### ### ### PLITC ### ### ###
# EOF
CHECKUPDATELIST1IN

   lxc-attach -n managed -- apt-get clean
   lxc-attach -n managed -- apt-get update
   if [ "$?" != "0" ]; then
      rm -rf /var/lib/lxc/managed/rootfs/etc/apt/sources.list
      echo "[ERROR] can't fetch update list"
      exit 1
   fi
fi

DEBVERSIONMANAGED=$(grep "VERSION_ID" /var/lib/lxc/managed/rootfs/etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
if [ "$DEBVERSIONMANAGED" = "8" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y upgrade
   if [ "$?" != "0" ]; then
      echo "[ERROR] can't upgrade the LXC Container"
      echo '... try manually "lxc-attach -n managed -- apt-get -y upgrade"'
      if [ "$?" != "0" ]; then
         echo "[ERROR] can't upgrade"
         rm -rf /var/lib/lxc/managed/rootfs/etc/apt/sources.list
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
         exit 1
      fi
   fi
   lxc-attach -n managed -- apt-get -y dist-upgrade
   if [ "$?" != "0" ]; then
      echo "[ERROR] can't dist-upgrade the LXC Container"
      echo '... try manually "lxc-attach -n managed -- apt-get -y dist-upgrade"'
      if [ "$?" != "0" ]; then
         echo "[ERROR] can't dist-upgrade"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
         exit 1
      fi
   fi
   lxc-attach -n managed -- apt-get -y autoremove
   if [ "$?" != "0" ]; then
      echo '... try manually "lxc-attach -n managed -- apt-get -y autoremove"'
      echo "[ERROR] can't autoremove the LXC Container"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
      exit 1
   fi
   lxc-attach -n managed -- apt-get -y install --reinstall systemd-sysv
   if [ "$?" != "0" ]; then
      echo '... try manually "lxc-attach -n managed -- apt-get -y install --reinstall systemd-sysv"'
      echo "[ERROR] can't reinstall systemd-sysv the LXC Container"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
      exit 1
   fi
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd.service
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd-control.socket
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd-kernel.socket
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/proc-sys-fs-binfmt_misc.automount

   lxc-stop -n managed

### ### ###
CHECKTEMPLATEDEB8=$(lxc-ls | grep -c "deb8template")
if [ "$CHECKTEMPLATEDEB8" = "1" ]; then
   : # dummy
else
   echo "" # dummy
if [ "$DEBVERSION" = "7" ]; then
   lxc-clone -o managed -n deb8template
else
   lxc-clone -M -B dir -o managed -n deb8template
fi
### ### ###
sed -i '/lxc.network.ipv4/d' /var/lib/lxc/deb8template/config
sed -i '/lxc.network.ipv6/d' /var/lib/lxc/deb8template/config
sed -i '0,/lxc.network.type = veth/s/lxc.network.type = veth//' /var/lib/lxc/deb8template/config
sed -i '0,/lxc.network.flags = up/s/lxc.network.flags = up//' /var/lib/lxc/deb8template/config
sed -i '0,/lxc.network.link = vswitch0/s/lxc.network.link = vswitch0//' /var/lib/lxc/deb8template/config
sed -i '0,/lxc.network.name = eth0/s/lxc.network.name = eth0//' /var/lib/lxc/deb8template/config
sed -i '0,/lxc.network.veth.pair = managed/s/lxc.network.veth.pair = managed//' /var/lib/lxc/deb8template/config
#/ sed -i '0,/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa/s/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa//' /var/lib/lxc/deb8template/config
sed -i '/lxc.network.hwaddr/d' /var/lib/lxc/deb8template/config
sed -i 's/managed1/deb8temp/g' /var/lib/lxc/deb8template/config
sed -i '/^\s*$/d' /var/lib/lxc/deb8template/config
### ### ###
#
#/ if [ "$DEBVERSION" = "8" ]; then
#/    sed -i '/lxc.autodev/d' /var/lib/lxc/deb8template/config
#/    sed -i '/lxc.kmsg/d' /var/lib/lxc/deb8template/config
#/ fi
#
### ### ###
echo "" # dummy
   ./hook_deb8.sh
echo "" # dummy
### ### ###
fi
### ### ###

   echo "... LXC Container (screen session): managed restarting ..."
   screen -d -m -S managed -- lxc-start -n managed
   sleep 1
   screen -list | grep "managed"
   echo "" # dummy
fi

### ### ###

CHECKMANAGEDIPTABLES1=$(lxc-attach -n managed -- dpkg -l | grep -c "iptables")
if [ "$CHECKMANAGEDIPTABLES1" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install iptables
fi

SYSCTLMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/sysctl.conf | awk '{print $4}' | head -n 1)
if [ X"$SYSCTLMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << SYSCTLFILEMANAGED > /var/lib/lxc/managed/rootfs/etc/sysctl.conf
### ### ### lxc-to-go // ### ### ###
#
net.ipv4.conf.eth0.forwarding=1
net.ipv4.conf.eth1.forwarding=1
net.ipv6.conf.eth0.forwarding=1
net.ipv6.conf.eth1.forwarding=1
net.ipv6.conf.all.forwarding=1
#
### ### ### // lxc-to-go ### ### ###
# EOF
SYSCTLFILEMANAGED
fi

lxc-attach -n managed -- sysctl -w net.ipv4.conf.eth0.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv4.conf.eth1.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.eth0.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.eth1.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1

### ### ###

RCLOCALMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/rc.local | awk '{print $4}' | head -n 1)
if [ X"$RCLOCALMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << RCLOCALFILEMANAGED > /var/lib/lxc/managed/rootfs/etc/rc.local
#!/bin/sh -e
### ### ### lxc-to-go // ### ### ###
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

##/ echo "stage0"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

##/ echo "stage0"
sysctl net.ipv4.conf.default.forwarding=1
sysctl net.ipv4.conf.eth0.forwarding=1
sysctl net.ipv4.conf.eth1.forwarding=1
sysctl net.ipv6.conf.eth0.forwarding=1
sysctl net.ipv6.conf.eth1.forwarding=1
sysctl net.ipv6.conf.all.forwarding=1

##/ echo "stage1"
##/ nat
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#/
# lxc1
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10001 -j DNAT --to-destination 192.168.254.101:10001
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10001 -j DNAT --to-destination 192.168.254.101:10001
# lxc2
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10002 -j DNAT --to-destination 192.168.254.102:10002
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10002 -j DNAT --to-destination 192.168.254.102:10002
# lxc3
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10003 -j DNAT --to-destination 192.168.254.103:10003
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10003 -j DNAT --to-destination 192.168.254.103:10003
# lxc4
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10004 -j DNAT --to-destination 192.168.254.104:10004
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10004 -j DNAT --to-destination 192.168.254.104:10004
# lxc5
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10005 -j DNAT --to-destination 192.168.254.105:10005
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10005 -j DNAT --to-destination 192.168.254.105:10005
# lxc6
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10006 -j DNAT --to-destination 192.168.254.106:10006
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10006 -j DNAT --to-destination 192.168.254.106:10006
# lxc7
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10007 -j DNAT --to-destination 192.168.254.107:10007
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10007 -j DNAT --to-destination 192.168.254.107:10007
# lxc8
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10008 -j DNAT --to-destination 192.168.254.108:10008
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10008 -j DNAT --to-destination 192.168.254.108:10008
# lxc9
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10009 -j DNAT --to-destination 192.168.254.109:10009
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10009 -j DNAT --to-destination 192.168.254.109:10009
# lxc10
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10010 -j DNAT --to-destination 192.168.254.110:10010
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10010 -j DNAT --to-destination 192.168.254.110:10010
#/

##/ echo "stage2"
# ip -6 rule add from 2001::/64 table 100
# ip r a 2000::/3 dev eth0 via fe80:: table 100

##/ echo "stage3"
### IPredator // ###
# route add -net 46.246.38.0 netmask 255.255.255.0 gw 192.168.254.254
#
# mkdir -p /dev/net
# mknod /dev/net/tun c 10 200
# chmod 666 /dev/net/tun
#
# systemctl restart openvpn
### // IPredator ###

exit 0
#
### ### ### // lxc-to-go ### ### ###
# EOF
RCLOCALFILEMANAGED
fi

CHECKMANAGEDNET=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/network/interfaces | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDNET" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDNETFILE > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
iface eth0 inet6 auto

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE

   lxc-stop -n managed

   echo "" # dummy
   echo "... LXC Container (screen session): managed restarting ..."
   screen -d -m -S managed -- lxc-start -n managed
   sleep 1
   screen -list | grep "managed"
   echo "" # dummy
fi

### DHCP-Service

CHECKMANAGEDDHCP=$(lxc-attach -n managed -- dpkg -l | grep -c "isc-dhcp-server")
if [ "$CHECKMANAGEDDHCP" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install isc-dhcp-server
fi

CHECKMANAGEDDHCPCONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/dhcp/dhcpd.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDDHCPCONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDDHCPCONFIGFILE > /var/lib/lxc/managed/rootfs/etc/dhcp/dhcpd.conf
### ### ### lxc-to-go // ### ### ###
#
# /etc/dhcpd.conf for primary DHCP server
#

#/ option local-proxy-config code 252 = text;
#/ option root-path "iscsi:freenas.domain.tld:6:3260:0:iqn.2015-01.tld.domain:iscsiboot";

authoritative;                                             # server is authoritative
option domain-name "privat.local";                         # the domain name issued
option domain-search "privat.local";                       # dns search
option domain-name-servers 192.168.254.254;                    # name servers issued

#/ option netbios-name-servers 192.168.254.254;                # netbios servers
#/ allow booting;                                          # allow for booting over the network
#/ allow bootp;                                            # allow for booting
#/ next-server 192.168.254.254;                                # TFTP server for booting
#/ filename "pxelinux.0";                                  # kernel for network booting
#/ ddns-update-style interim;                              # setup dynamic DNS updates
#/ ddns-updates on;
#/ ddns-domainname "extern.global.";                       # domain name for DDNS updates
#/ do-forward-updates on;
#/ ddns-rev-domainname "in-addr.arpa.";

default-lease-time 86400;
max-lease-time 604800;

#/ key dhcp.domain.tld {
#/     algorithm hmac-md5;
#/     secret "... SECRETHASH ...";
#/ }
#/ zone extern.global.
#/ {
#/     primary 0.0.0.0;
#/     key dhcp.domain.tld;
#/ }
#/ zone 1.168.192.in-addr.arpa.
#/ {
#/     primary 0.0.0.0;
#/     key dhcp.domain.tld;
#/ }

#/ failover peer "dhcp-failover" {                         # fail over configuration
#/          primary;                                       # this is the secondary
#/          address 192.168.254.254;                           # our ip address
#/          port 647;
#/          peer address 192.168.254.253;                      # primary's ip address
#/          peer port 647;
#/          max-response-delay 60;
#/          max-unacked-updates 10;
#/          mclt 3600;
#/          split 128;                                     # for primary only
#/          load balance max seconds 3;
#/ }

subnet 192.168.254.0 netmask 255.255.255.0                   # zone to issue addresses from
{
        pool {
                #/ failover peer "dhcp-failover";          # pool for dhcp, bootp leases with failover
                #/ option local-proxy-config "http://192.168.254.254/proxy.pac";

                option routers 192.168.254.254;
                range 192.168.254.101 192.168.254.200;

### fixed-address // ###
#
#/  host managed {
#/    hardware ethernet aa:bb:c0:0c:bb:aa;
#/    fixed-address managed.privat.local;
#/  }
#
### // fixed-address ###

           }
#/         pool {                                          # accomodate our bootp clients here no replication and failover
#/                option routers 10.0.0.1;
#/                range 10.0.0.100 10.0.0.200;
#/         }

        allow unknown-clients;
        ignore client-updates;
}

log-facility local7;

#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDDHCPCONFIGFILE
   lxc-attach -n managed -- systemctl restart isc-dhcp-server
fi

### ### ###

### DNS-Service (unbound)

CHECKMANAGEDDNS=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "unbound")
if [ "$CHECKMANAGEDDNS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install unbound
fi

CHECKMANAGEDDNSCONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/unbound/unbound.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDDNSCONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDDNSCONFIGFILE > /var/lib/lxc/managed/rootfs/etc/unbound/unbound.conf
### ### ### lxc-to-go // ### ### ###
#
server:
### < --- server // --- > ###
verbosity: 2
 
# interface: 192.168.254.254
# interface: 192.168.254.254@5003
# interface: 2001::1
 
# outgoing-interface: 192.168.254.254
# outgoing-interface: 192.168.254.254@5003
# outgoing-interface: 2001::1
 
access-control: 0.0.0.0/0 allow
access-control: ::/0 allow
 
outgoing-port-permit: 1025-65535
outgoing-port-avoid: 0-1024
 
harden-large-queries: "yes"
harden-short-bufsize: "yes"
 
statistics-interval: 60
 
#/ logfile: "/usr/local/etc/unbound/unbound.log"
 
#/ root-hints: "/usr/local/etc/unbound/named.cache"
#/ auto-trust-anchor-file: "/usr/local/etc/unbound/root.key"
 
port: 53
 
do-ip4: yes
do-ip6: yes
do-udp: yes
do-tcp: yes
 
hide-identity: yes
hide-version: yes
harden-glue: yes
harden-dnssec-stripped: yes
 
use-caps-for-id: yes
 
cache-min-ttl: 3600
cache-max-ttl: 86400
 
prefetch: yes
num-threads: 2
 
max-udp-size: 512
edns-buffer-size: 512
 
# with libevent2
outgoing-range: 8192
num-queries-per-thread: 4096
 
msg-cache-slabs: 8
rrset-cache-slabs: 8
infra-cache-slabs: 8
key-cache-slabs: 8
 
rrset-cache-size: 256m
msg-cache-size: 128m
 
so-rcvbuf: 1m
 
unwanted-reply-threshold: 10000
val-clean-additional: yes
### < --- // server --- > ###
python:
 
remote-control:
 
# forward-zone:
# name: "."
# forward-addr: 213.73.91.35  # dnscache.berlin.ccc.de
# forward-addr: 74.82.42.42   # Hurricane Electric
# forward-addr: 4.2.2.4       # Level3 Verizon
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDDNSCONFIGFILE
   lxc-attach -n managed -- systemctl restart unbound
fi

### ### ###

### RA-Service

CHECKMANAGEDIPV6D=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "radvd")
if [ "$CHECKMANAGEDIPV6D" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install radvd
fi

touch /var/lib/lxc/managed/rootfs/etc/radvd.conf
CHECKMANAGEDIPV6CONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/radvd.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDIPV6CONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDIPV6CONFIGFILE > /var/lib/lxc/managed/rootfs/etc/radvd.conf
### ### ### lxc-to-go // ### ### ###
#
interface eth1
{ 
        AdvSendAdvert on;
        MinRtrAdvInterval 3; 
        MaxRtrAdvInterval 10;
        prefix fd00:aaaa:0001::/64
	{ 
                AdvOnLink on; 
                AdvAutonomous on; 
                AdvRouterAddr on; 
        };
	AdvDefaultPreference high;
	RDNSS fd00:aaaa:0001::1 { };
};
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDIPV6CONFIGFILE
   lxc-attach -n managed -- service radvd restart
fi

### ### ###

### network tools

CHECKMANAGEDIPUTILS=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "iputils-ping")
if [ "$CHECKMANAGEDIPUTILS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install iputils-ping
fi

CHECKMANAGEDTRACEROUTE=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "traceroute")
if [ "$CHECKMANAGEDTRACEROUTE" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install traceroute
fi

### ### ###

### NEW IP - Desktop Environment // ###
   if [ "$GETENVIRONMENT" = "desktop" ]; then
      : # dummy
#/ ipv4
      #/ killall dhclient
      if [ -e "$UDEVNET" ]; then
         #/ dhclient "$GETBRIDGEPORT0" >/dev/null 2>&1
         #/ route del default dev "$GETBRIDGEPORT0" >/dev/null 2>&1
         if [ "$DEBVERSION" = "7" ]; then
            pgrep -f "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 kill -9
            pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 kill -9
         fi
         if [ "$DEBVERSION" = "8" ]; then
            ps -ax | grep "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 kill -9
            ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 kill -9
         fi
         ip addr flush "$GETBRIDGEPORT0"
         echo "" # dummy
         echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT $GETBRIDGEPORT0"
      else
         #/ dhclient eth0 >/dev/null 2>&1
         #/ route del default dev eth0 >/dev/null 2>&1
         if [ "$DEBVERSION" = "7" ]; then
            pgrep -f "[dhclient] eth0" | awk '{print $1}' | xargs -L1 kill -9
            pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 kill -9
         fi
         if [ "$DEBVERSION" = "8" ]; then
            ps -ax | grep "[dhclient] eth0" | awk '{print $1}' | xargs -L1 kill -9
            ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 kill -9
         fi
         ip addr flush eth0
         echo "" # dummy
         echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT 'eth0'"
      fi
      dhclient vswitch0 >/dev/null 2>&1
### fix //
CHECKGETIPV4DEFAULTGATEWAY3=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
if [ "$CHECKGETIPV4DEFAULTGATEWAY3" = "2" ]; then
   route del default
fi
### // fix
#/ ipv6
      if [ -e "$UDEVNET" ]; then
         #/ ifconfig "$GETBRIDGEPORT0" | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I {} ifconfig vswitch0 inet6 add {} >/dev/null 2>&1
         ip -6 route del ::/0 >/dev/null 2>&1
         echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
      else
         #/ ifconfig eth0 | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I {} ifconfig vswitch0 inet6 add {} >/dev/null 2>&1
         ip -6 route del ::/0 >/dev/null 2>&1
         echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
      fi
#/ container
      #/ lxc-attach -n managed -- pkill dhclient
      lxc-attach -n managed -- killall dhclient >/dev/null 2>&1
      lxc-attach -n managed -- ip addr flush eth0 >/dev/null 2>&1
      lxc-attach -n managed -- dhclient eth0 >/dev/null 2>&1
      lxc-attach -n managed -- ip -6 route del ::/0 >/dev/null 2>&1
      lxc-attach -n managed -- echo "2" > /proc/sys/net/ipv6/conf/eth0/accept_ra
   fi 
### NEW IP - Desktop Environment // ###

### ### ### ### ### ### ### ### ###
echo "" # printf
printf "\033[1;31mbootstrap finished\033[0m\n"
### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'start')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'stop')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'create')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKBRIDGE1=$(ifconfig | grep -c "vswitch0")
if [ "$CHECKBRIDGE1" = "0" ]; then
   ### ### ### ### ### ### ### ### ###
   echo "" # printf
   printf "\033[1;31mCan't find the Bridge Zones, execute the 'bootstrap' command at first\033[0m\n"
   ### ### ### ### ### ### ### ### ###
fi

CHECKLXCCONTAINER=$(lxc-ls | egrep -c "managed|deb7template|deb8template")
if [ "$CHECKLXCCONTAINER" = "3" ]; then
   : # dummy
else
   ### ### ### ### ### ### ### ### ###
   echo "" # printf
   printf "\033[1;31mCan't find all nessessary default lxc container, delete the 'managed|deb7template|deb8template' lxc and execute the 'bootstrap' command again\033[0m\n"
   ### ### ### ### ### ### ### ### ###
fi

echo "Please enter the new LXC Container name:"
read LXCNAME;
if [ -z "$LXCNAME" ]; then
   echo "[ERROR] empty name"
   exit 1
fi

CHECKLXCEXIST=$(lxc-ls | grep -c "$LXCNAME")
if [ "$CHECKLXCEXIST" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] lxc already exists!"
   exit 1
fi

echo ""
echo "Choose the LXC template:"
echo "1) wheezy"
echo "2) jessie"
read LXCCREATETEMPLATE;
   if [ -z "$LXCCREATETEMPLATE" ]; then
      echo "[ERROR] nothing selected"
      exit 1
   fi
case $LXCCREATETEMPLATE in
   1) echo "select: wheezy"
      lxc-clone -o deb7template -n "$LXCNAME"
      if [ $? -eq 0 ]
      then
         : # dummy
      else
         echo "" # dummy
         echo "[ERROR] lxc-clone failed!"
         read -p "Do you wish to remove this corrupt LXC Container: '"$LXCNAME"' ? (y/n)" LXCCREATEFAILED
         if [ "$LXCCREATEFAILED" = "y" ]; then
            lxc-destroy -n "$LXCNAME"
         fi
         exit 1
      fi
   ;;
   2) echo "select: jessie"
      lxc-clone -o deb7template -n "$LXCNAME"
      if [ $? -eq 0 ]
      then
         : # dummy
      else
         echo "" # dummy
         echo "[ERROR] lxc-clone failed!"
         read -p "Do you wish to remove this corrupt LXC Container: '"$LXCNAME"' ? (y/n)" LXCCREATEFAILED
         if [ "$LXCCREATEFAILED" = "y" ]; then
            lxc-destroy -n "$LXCNAME"
         fi
         exit 1
      fi
   ;;
esac

### randomized MAC address // ###
#/ RANDOMMAC1=$(shuf -i 10-99 -n 1)
#/ RANDOMMAC2=$(shuf -i 10-99 -n 1)
#/ sed -i 's/aa:bb:01:01:bb:aa/aa:bb:'"$RANDOMMAC1"':'"$RANDOMMAC2"':bb:aa/' /var/lib/lxc/"$LXCNAME"/config
#
#/ CHECKMAC1=$(grep "aa:bb" /var/lib/lxc/"$LXCNAME"/config | sed 's/lxc.network.hwaddr=//')
#/ CHECKMAC2=$(grep -c "$CHECKMAC1" /var/lib/lxc/*/config | egrep -v ":0")
#/ if [ -z "$CHECKMAC2" ]; then
#/    : # dummy
#/ else
#/    sed -i 's/aa:bb:01:01:bb:aa/aa:bb:'"$RANDOMMAC1"':'"$RANDOMMAC2"':bb:aa/' /var/lib/lxc/"$LXCNAME"/config
#/    echo "try random mac for the second time"
#/ fi
### // randomized MAC address ###

echo "$LXCNAME" > /var/lib/lxc/"$LXCNAME"/rootfs/etc/hostname

echo ""
read -p "Do you wish to start this LXC Container: "$LXCNAME" ? (y/n) " LXCSTART
if [ "$LXCSTART" = "y" ]; then
  screen -d -m -S "$LXCNAME" -- lxc-start -n "$LXCNAME"
  echo ""
  echo "... starting screen session ..."
  sleep 1
  screen -list | grep "$LXCNAME"
  echo ""
  echo "That's it"
else
  echo ""
  echo "That's it"
fi

### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'delete')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
*)
printf "\033[1;31mWARNING: lxc-to-go is experimental and its not ready for production. Do it at your own risk.\033[0m\n"
echo "" # usage
echo "usage: $0 { bootstrap | start | stop | create | delete }"
;;
esac
exit 0
### ### ### PLITC ### ### ###
# EOF
