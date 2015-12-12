#!/bin/sh
### ### ### lxc-to-go // ### ### ###

### ### ### CUSTOM // ### ### ###
CUSTOMINTERFACE=$(echo "wlan0")
### ### ### // CUSTOM ### ### ###

echo "<--- --- --- lxc-to-go (server variant) custom interface support // --- --- --->"

cp -prf ../lxc-to-go.sh lxc-to-go-ci.sh

### MOD // ###
#
sed -i 's/eth0/'"$CUSTOMINTERFACE"'/g' lxc-to-go-ci.sh
#
sed -i 's/-o '"$CUSTOMINTERFACE"' -j MASQUERADE/-o eth0 -j MASQUERADE/g' lxc-to-go-ci.sh
sed -i 's/PREROUTING -i '"$CUSTOMINTERFACE"'/PREROUTING -i eth0/g' lxc-to-go-ci.sh
sed -i 's/lxc.network.name='"$CUSTOMINTERFACE"'/lxc.network.name=eth0/g' lxc-to-go-ci.sh
sed -i 's/auto '"$CUSTOMINTERFACE"'/auto eth0/g' lxc-to-go-ci.sh
sed -i 's/iface '"$CUSTOMINTERFACE"' inet dhcp/iface eth0 inet dhcp/g' lxc-to-go-ci.sh
sed -i 's/iface '"$CUSTOMINTERFACE"' inet6 auto/iface eth0 inet6 auto/g' lxc-to-go-ci.sh
sed -i 's/iface '"$CUSTOMINTERFACE"' inet manual/iface eth0 inet manual/g' lxc-to-go-ci.sh
sed -i 's/iface '"$CUSTOMINTERFACE"' inet6 manual/iface eth0 inet6 manual/g' lxc-to-go-ci.sh
sed -i 's/network.name = '"$CUSTOMINTERFACE"'/network.name = eth0/g' lxc-to-go-ci.sh
sed -i 's/managed -- sysctl -w net.ipv4.conf.'"$CUSTOMINTERFACE"'.forwarding=1/managed -- sysctl -w net.ipv4.conf.eth0.forwarding=1/g' lxc-to-go-ci.sh
sed -i 's/managed -- ip addr flush '"$CUSTOMINTERFACE"'/managed -- ip addr flush eth0/g' lxc-to-go-ci.sh
sed -i 's/managed -- dhclient '"$CUSTOMINTERFACE"'/managed -- dhclient eth0/g' lxc-to-go-ci.sh
sed -i 's/'"$CUSTOMINTERFACE"'\/accept_ra/eth0\/accept_ra/g' lxc-to-go-ci.sh
sed -i 's/managed -- sysctl -w net.ipv6.conf.'"$CUSTOMINTERFACE"'.forwarding=1/managed -- sysctl -w net.ipv6.conf.eth0.forwarding=1/g' lxc-to-go-ci.sh
sed -i 's/'"$CUSTOMINTERFACE"'.forwarding=1 # LXC/eth0.forwarding=1 # LXC/g' lxc-to-go-ci.sh
sed -i 's/'"$CUSTOMINTERFACE"'.forwarding=1    # LXC/eth0.forwarding=1    # LXC/g' lxc-to-go-ci.sh
#
### // MOD ###

cp -prf lxc-to-go-ci.sh ../lxc-to-go-ci.sh
rm -f lxc-to-go-ci.sh

### ### ###

cp -prf ../lxc-to-go-provisioning.sh lxc-to-go-ci-provisioning.sh

### MOD2 // ###
#
sed -i 's/ifconfig eth0/ifconfig '"$CUSTOMINTERFACE"'/g' lxc-to-go-ci-provisioning.sh
#
sed -i 's/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/iptables -t nat -A PREROUTING -i '"$CUSTOMINTERFACE"' -p tcp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/g' lxc-to-go-ci-provisioning.sh
sed -i 's/iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/iptables -t nat -A PREROUTING -i '"$CUSTOMINTERFACE"' -p udp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/g' lxc-to-go-ci-provisioning.sh
#
### // MOD2 ###

cp -prf lxc-to-go-ci-provisioning.sh ../lxc-to-go-ci-provisioning.sh
rm -f lxc-to-go-ci-provisioning.sh

echo "<--- --- --- // lxc-to-go (server variant) custom interface support  --- --- --->"
exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
