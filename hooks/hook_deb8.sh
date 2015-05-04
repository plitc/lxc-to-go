#!/bin/sh
### ### ### lxc-to-go // ### ### ###
echo "<--- --- --- debian 8 lxc template hooks // --- --- --->"

run(){
   # execute commands inside the lxc template
   lxc-attach -n deb8template -- "$@"
}

### EXAMPLE // ###
#

#/ run apt-get -y install iputils-ping

#
### // EXAMPLE ###

echo "<--- --- --- // debian 8 lxc template hooks --- --- --->"
#/ exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
