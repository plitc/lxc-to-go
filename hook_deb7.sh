#!/bin/sh
### ### ### PLITC ### ### ###
echo "<--- --- --- debian 7 lxc template hooks // --- --- --->"

run(){
   # execute inside lxc
   run1=$1
   lxc-attach -n deb7template -- $1
}

### EXAMPLE // ###
#

#/ run apt-get -y install iputils-ping

#
### // EXAMPLE ###

echo "<--- --- --- // debian 7 lxc template hooks --- --- --->"
#/ exit 0
### ### ### PLITC ### ### ###
# EOF
