#!/bin/sh
### ### ### PLITC ### ### ###
echo "<--- --- --- debian 8 lxc template hooks // --- --- --->"

run(){
   # execute inside lxc
   run1=$1
   lxc-attach -n deb8template -- $1
}

### EXAMPLE // ###
#

#/ run apt-get -y install iputils-ping

#
### // EXAMPLE ###

echo "<--- --- --- // debian 8 lxc template hooks --- --- --->"
#/ exit 0
### ### ### PLITC ### ### ###
# EOF
