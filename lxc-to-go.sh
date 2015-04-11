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
