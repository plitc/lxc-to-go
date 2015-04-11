#!/bin/sh

### LICENSE - (BSD 2-Clause) // ###
#
# Copyright (c) 2015, Daniel Plominski (Plominski IT Consulting)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE - (BSD 2-Clause) ###

### ### ### PLITC // ### ### ###

### stage0 // ###
DEBIAN=$(grep "ID" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
MYNAME=$(whoami)
### // stage0 ###

case "$1" in
'bootstrap')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "8" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You need Debian 8 (Jessie) Version"
   exit 1
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

LXC=$(/usr/bin/dpkg -l | grep lxc | awk '{print $2}')
if [ -z "$LXC" ]; then
    echo "<--- --- --->"
    echo "need lxc"
    echo "<--- --- --->"
    apt-get update
    apt-get install lxc
    echo "<--- --- --->"
fi

BRIDGEUTILS=$(/usr/bin/dpkg -l | grep bridge-utils | awk '{print $2}')
if [ -z "$BRIDGEUTILS" ]; then
    echo "<--- --- --->"
    echo "need bridge-utils"
    echo "<--- --- --->"
    apt-get update
    apt-get install bridge-utils
    echo "<--- --- --->"
fi

sleep 1
    echo ""
    lxc-checkconfig
    if [ $? -eq 0 ]
    then
       : # dummy
    else
       echo "[ERROR] lxc-checkconfig failed!"
       exit 1
    fi
sleep 1

## modify grub

CHECKGRUB1=$(grep "GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "cgroup_enable=memory" | grep -c "swapaccount=1")
if [ "$CHECKGRUB1" = "1" ]; then
    : # dummy
else
    cp -prfv /etc/default/grub /etc/default/grub_BACKUP_lxctogo
    sed -i '/GRUB_CMDLINE_LINUX=/s/.$//' /etc/default/grub
    sed -i '/GRUB_CMDLINE_LINUX=/s/$/ cgroup_enable=memory swapaccount=1"/' /etc/default/grub

   ### grub update

   echo "" # dummy
   sleep 2
   grub-mkconfig
   echo "" # dummy
   sleep 2
   update-grub
   if [ "$?" != "0" ]; then
      echo "" # dummy
      sleep 5
      echo "[Error] something goes wrong let's restore the old configuration!" 1>&2
      cp -prfv /etc/default/grub_BACKUP_lxctogo /etc/default/grub
      echo "" # dummy
      sleep 2
      grub-mkconfig
      echo "" # dummy
      sleep 2
      update-grub
      exit 1
   fi
   echo ""
   echo "Please Reboot your System immediately! and continue the bootstrap"
   exit 0
fi

CHECKGRUB2=$(cat /proc/cmdline | grep "cgroup_enable=memory" | grep -c "swapaccount=1")
if [ "$CHECKGRUB2" = "1" ]; then
    : # dummy
else
   echo ""
   echo "Please Reboot your System immediately! and continue the bootstrap"
   exit 0
fi

### ### ###

CREATEBRIDGE0=$(ip a | grep -c "vswitch0:")
if [ "$CREATEBRIDGE0" = "1" ]; then
    : # dummy
else
   brctl addbr vswitch0

   UDEVNET="/etc/udev/rules.d/70-persistent-net.rules"
   if [ -e $CONFIGCHECK ]; then
      GETBRIDGEPORT0=$(grep 'SUBSYSTEM=="net"' /etc/udev/rules.d/70-persistent-net.rules | grep "eth" | head -n 1 | tr ' ' '\n' | grep "NAME" | sed 's/NAME="//' | sed 's/"//')
      brctl addif vswitch0 "$GETBRIDGEPORT0"
   else
      brctl addif vswitch0 eth0
   fi
fi

### ### ###
sleep 2
### ### ###

CHECKLXCMANAGED=$(lxc-ls | grep -c "managed")
if [ "$CHECKLXCMANAGED" = "1" ]; then
    : # dummy
else
   lxc-create -n managed -t debian
fi

### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'start')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "8" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You need Debian 8 (Jessie) Version"
   exit 1
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'stop')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "8" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You need Debian 8 (Jessie) Version"
   exit 1
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'create')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "8" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You need Debian 8 (Jessie) Version"
   exit 1
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
   ;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'delete')
### stage1 // ###
case $DEBIAN in
debian)
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "8" ]; then
   : # dummy
else
   echo "" # dummy
   echo "" # dummy
   echo "[Error] You need Debian 8 (Jessie) Version"
   exit 1
fi

#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###



### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
;;
*)
   # error 1
   echo "" # dummy
   echo "" # dummy
   echo "[Error] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
*)
echo ""
echo "usage: $0 { bootstrap | start | stop | create | delete }"
;;
esac
exit 0
### ### ### PLITC ### ### ###
# EOF
