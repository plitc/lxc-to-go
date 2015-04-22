#!/bin/sh
### ### ### PLITC ### ### ###
echo "<--- --- --- flavor hooks // --- --- --->"

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

echo "<--- --- --- // flavor hooks --- --- --->"
#/ exit 0
### ### ### PLITC ### ### ###
# EOF
