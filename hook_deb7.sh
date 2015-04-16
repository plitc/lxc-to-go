#!/bin/sh
### ### ### PLITC ### ### ###
echo "<--- --- --- debian 7 lxc template hooks // --- --- --->"

run(){
   # execute inside lxc
   run1=$1
   lxc-attach -n deb7template -- $1
}

#/ run echo ""

echo "<--- --- --- // debian 7 lxc template hooks --- --- --->"
#/ exit 0
### ### ### PLITC ### ### ###
# EOF
