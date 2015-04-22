#!/bin/sh
### ### ### PLITC ### ### ###
echo "<--- --- --- flavor hooks // --- --- --->"

run(){
   # execute inside lxc
   run1=$1
   lxc-attach -n "$LXCCREATENAME" -- $1
}

### EXAMPLE // ###
#

run (echo "inside hook")

#
### // EXAMPLE ###

echo "<--- --- --- // flavor hooks --- --- --->"
#/ exit 0
### ### ### PLITC ### ### ###
# EOF
