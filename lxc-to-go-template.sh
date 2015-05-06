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
DEBIAN=$(grep -s "ID" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep -s "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
MYNAME=$(whoami)
#
PRG="$0"
##/ need this for relative symlinks
while [ -h "$PRG" ] ;
   do
      PRG=`readlink "$PRG"`
   done
DIR=`dirname "$PRG"`
#
ADIR="$PWD"
### // stage0 ###

### stage1 // ###
if [ "$DEBIAN" = "debian" ]; then
   : # dummy
else
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
fi
### stage2 // ###

### // stage2 ###
#
### stage3 // ###
if [ "$MYNAME" = "root" ]; then
   : # dummy
else
   : # dummy
   : # dummy
   echo "[ERROR] You must be root to run this script"
   exit 1
fi
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
   : # dummy
   else
   : # dummy
   : # dummy
   echo "[ERROR] You need Debian 7 (Wheezy) or 8 (Jessie) Version"
   exit 1
   fi
fi
CHECKLXCINSTALL=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
DIALOG=$(/usr/bin/which dialog)
if [ -z "$DIALOG" ]; then
   echo "<--- --- --->"
   echo "need dialog"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install dialog
   echo "<--- --- --->"
fi
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKBRIDGE1=$(ifconfig | grep -c "vswitch0")
if [ "$CHECKBRIDGE1" = "0" ]; then
   ### ### ### ### ### ### ### ### ###
   echo "" # printf
   printf "\033[1;31mCan't find the Bridge Zones, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
   ### ### ### ### ### ### ### ### ###
fi

CHECKLXCCONTAINER=$(lxc-ls | egrep -c "managed|deb7template|deb8template")
if [ "$CHECKLXCCONTAINER" = "3" ]; then
   : # dummy
else
   ### ### ### ### ### ### ### ### ###
   echo "" # printf
   printf "\033[1;31mCan't find all nessessary default lxc container, delete the 'managed|deb7template|deb8template' lxc and execute the 'bootstrap' command again\033[0m\n"
   exit 1
   ### ### ### ### ### ### ### ### ###
fi

### TEMPLATE // ###

LISTTEMPLATEFILE1="/etc/lxc-to-go/tmp/choose_templ1.tmp"
LISTTEMPLATEFILE2="/etc/lxc-to-go/tmp/choose_templ2.tmp"
LISTTEMPLATEFILE3="/etc/lxc-to-go/tmp/choose_templ3.tmp"
LISTTEMPLATEFILE4="/etc/lxc-to-go/tmp/choose_templ4.tmp"
LISTTEMPLATEFILE5="/etc/lxc-to-go/tmp/choose_templ5.tmp"

ls -tr "$DIR"/hooks/templates/ > "$LISTTEMPLATEFILE1"
nl "$LISTTEMPLATEFILE1" | sed 's/ //g' > "$LISTTEMPLATEFILE2"
/bin/sed 's/$/ off/' "$LISTTEMPLATEFILE2" > "$LISTTEMPLATEFILE3"

dialog --radiolist "Choose one template:" 45 80 60 --file "$LISTTEMPLATEFILE3" 2>"$LISTTEMPLATEFILE4"
list1=$?
case $list1 in
   0)
      echo "" # dummy
      echo "" # dummy
      awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,h[$1]}' "$LISTTEMPLATEFILE3" "$LISTTEMPLATEFILE4" | awk '{print $2}' | sed 's/"//g' > "$LISTTEMPLATEFILE5"
      GETTEMPLATE=$(cat "$LISTTEMPLATEFILE5")
      #/ cp -prf "$DIR"/hooks/templates/"$GETTEMPLATE" "$DIR"/hooks/hook_provisioning.sh
      cp -prf "$DIR"/hooks/templates/"$GETTEMPLATE" /etc/lxc-to-go/hook_provisioning.sh
      : # dummy
   ;;
   1)
      echo "" # dummy
      echo "" # dummy
      exit 0
   ;;
   255)
      echo "" # dummy
      echo "" # dummy
      echo "[ESC] key pressed."
      exit 0
   ;;
esac

### // TEMPLATE ###

### TEMPLATE BUILD STATUS // ###

TEMPLATESTATUS1=$(cat "$DIR"/hooks/template-status | sed -n '/OK/,/WARNING/p' | grep "$GETTEMPLATE")
TEMPLATESTATUS2=$(cat "$DIR"/hooks/template-status | sed -n '/WARNING/,/FAIL/p' | grep "$GETTEMPLATE")
TEMPLATESTATUS3=$(cat "$DIR"/hooks/template-status | sed -n '/FAIL/,//p' | grep "$GETTEMPLATE")

if [ "$GETTEMPLATE" = "$TEMPLATESTATUS1" ]; then
   echo "" # dummy
   echo "STATUS:"
   printf "\033[1;32mBuilding process could be OK\033[0m\n"
fi

if [ "$GETTEMPLATE" = "$TEMPLATESTATUS2" ]; then
   echo "" # dummy
   echo "STATUS:"
   printf "\033[1;33mBuilding process could be with warnings (please read the github.com/plitc/lxc-to-go README)\033[0m\n"
fi

if [ "$GETTEMPLATE" = "$TEMPLATESTATUS3" ]; then
   echo "" # dummy
   echo "STATUS:"
   printf "\033[1;31mBuilding process could be faulty (please read the github.com/plitc/lxc-to-go README)\033[0m\n"
fi

### // TEMPLATE BUILD STATUS ###

### ### ###
echo "" # dummy
echo "" # dummy
printf "\033[1;31mlxc-to-go template selection finished.\033[0m\n"
### ### ###

### ### ### ### ### ### ### ### ###
#
### // stage4 ###
#
### // stage3 ###
#
### // stage2 ###
exit 0
### ### ### PLITC ### ### ###
# EOF
