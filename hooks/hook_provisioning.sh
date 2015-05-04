#!/bin/sh
### ### ### lxc-to-go // ### ### ###
echo "<--- --- --- provisioning hooks // --- --- --->"

run(){
   # execute commands inside the lxc template
   lxc-attach -n "$LXCCREATENAME" -- "$@"
}

### EXAMPLE // ###
#

run echo example

#
### // EXAMPLE ###

echo "<--- --- --- // provisioning hooks --- --- --->"
#/ exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
