#!/bin/sh
### ### ### lxc-to-go // ### ### ###
echo "<--- --- --- lxc-to-go (server variant) wlan support  // --- --- --->"

cp -prf ../lxc-to-go.sh lxc-to-go_wlan.sh

### MOD // ###
#
sed -i "s/eth0/wlan0/g" lxc-to-go_wlan.sh
#
### // MOD ###

cp -prf lxc-to-go_wlan.sh ../lxc-to-go_wlan.sh
rm -f lxc-to-go_wlan.sh

echo "<--- --- --- // lxc-to-go (server variant) wlan support  --- --- --->"
exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
