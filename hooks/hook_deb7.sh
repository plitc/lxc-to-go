#!/bin/sh
### ### ### lxc-to-go // ### ### ###
echo "<--- --- --- debian 7 lxc template hooks // --- --- --->"

run(){
   # execute commands inside the lxc template
   lxc-attach -n deb7template -- "$@"
}

### EXAMPLE // ###
#

#/ run apt-get -y install iputils-ping

#
### // EXAMPLE ###

echo "<--- --- --- // debian 7 lxc template hooks --- --- --->"
#/ exit 0
### ### ### // lxc-to-go ### ### ###
# EOF
