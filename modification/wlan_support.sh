#!/bin/sh
### ### ### lxc-to-go // ### ### ###
echo "<--- --- --- lxc-to-go (server variant) wlan support  // --- --- --->"

cp -prf ../lxc-to-go.sh lxc-to-go_wlan.sh

### MOD // ###
#
sed -i 's/eth0/wlan0/g' lxc-to-go_wlan.sh
#
sed -i 's/-o wlan0 -j MASQUERADE/-o eth0 -j MASQUERADE/g' lxc-to-go_wlan.sh
sed -i 's/PREROUTING -i wlan0/PREROUTING -i eth0/g' lxc-to-go_wlan.sh
sed -i 's/lxc.network.name=wlan0/lxc.network.name=eth0/g' lxc-to-go_wlan.sh
sed -i 's/auto wlan0/auto eth0/g' lxc-to-go_wlan.sh
sed -i 's/iface wlan0 inet dhcp/iface eth0 inet dhcp/g' lxc-to-go_wlan.sh
sed -i 's/iface wlan0 inet6 auto/iface eth0 inet6 auto/g' lxc-to-go_wlan.sh
sed -i 's/iface wlan0 inet manual/iface eth0 inet manual/g' lxc-to-go_wlan.sh
sed -i 's/iface wlan0 inet6 manual/iface eth0 inet6 manual/g' lxc-to-go_wlan.sh
sed -i 's/network.name = wlan0/network.name = eth0/g' lxc-to-go_wlan.sh
sed -i 's/managed -- sysctl -w net.ipv4.conf.wlan0.forwarding=1/managed -- sysctl -w net.ipv4.conf.eth0.forwarding=1/g' lxc-to-go_wlan.sh
sed -i 's/managed -- ip addr flush wlan0/managed -- ip addr flush eth0/g' lxc-to-go_wlan.sh
sed -i 's/managed -- dhclient wlan0/managed -- dhclient eth0/g' lxc-to-go_wlan.sh
sed -i 's/wlan0\/accept_ra/eth0\/accept_ra/g' lxc-to-go_wlan.sh
sed -i 's/managed -- sysctl -w net.ipv6.conf.wlan0.forwarding=1/managed -- sysctl -w net.ipv6.conf.eth0.forwarding=1/g' lxc-to-go_wlan.sh
sed -i 's/wlan0.forwarding=1 # LXC/eth0.forwarding=1 # LXC/g' lxc-to-go_wlan.sh
sed -i 's/wlan0.forwarding=1    # LXC/eth0.forwarding=1    # LXC/g' lxc-to-go_wlan.sh
#
### // MOD ###

cp -prf lxc-to-go_wlan.sh ../lxc-to-go_wlan.sh
rm -f lxc-to-go_wlan.sh

### ### ###

cp -prf ../lxc-to-go-provisioning.sh lxc-to-go_wlan-provisioning.sh

### MOD2 // ###
#
sed -i 's/ifconfig eth0/ifconfig wlan0/g' lxc-to-go_wlan-provisioning.sh
#
sed -i 's/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/g' lxc-to-go_wlan-provisioning.sh
sed -i 's/iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/iptables -t nat -A PREROUTING -i wlan0 -p udp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST/g' lxc-to-go_wlan-provisioning.sh
#
### // MOD2 ###

cp -prf lxc-to-go_wlan-provisioning.sh ../lxc-to-go_wlan-provisioning.sh
rm -f lxc-to-go_wlan-provisioning.sh

echo "<--- --- --- // lxc-to-go (server variant) wlan support  --- --- --->"
exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
