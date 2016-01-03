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
DEBIAN=$(grep -s "ID=" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep -s "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
DEBTESTVERSION=$(grep -s "PRETTY_NAME" /etc/os-release | awk '{print $3}' | sed 's/"//g' | grep -c "stretch/sid")
MYNAME=$(whoami)

PRG="$0"
##/ need this for relative symlinks
   while [ -h "$PRG" ] ;
   do
         PRG=$(readlink "$PRG")
   done
DIR=$(dirname "$PRG")

#// function: check state (version: 1.1)
check()
{
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
   #/sleep 2
else
   echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
   sleep 1
   exit 1
fi
}

#// FUNCTION: spinner (Version 1.0)
spinner() {
   local pid=$1
   local delay=0.01
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
         local temp=${spinstr#?}
         printf " [%c]  " "$spinstr"
         local spinstr=$temp${spinstr%"$temp"}
         sleep $delay
         printf "\b\b\b\b\b\b"
   done
   printf "    \b\b\b\b"
}

#// FUNCTION: clean up tmp files (Version 1.0)
cleanup() {
   rm -rf /etc/lxc-to-go/tmp/*
}

#// FUNCTION: run script as root (Version 1.0)
checkrootuser() {
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// FUNCTION: check debian based distributions (Version 1.0)
checkdebiandistribution() {
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
else
   if [ "$DEBVERSION" = "8" ]; then
      : # dummy
   else
      if [ "$DEBTESTVERSION" = "1" ]; then
         : # dummy
      else
         if [ "$DEBIAN" = "linuxmint" ]; then
            : # dummy
         else
            if [ "$DEBIAN" = "ubuntu" ]; then
               : # dummy
            else
               if [ "$DEBIAN" = "devuan" ]; then
                  : # dummy
               else
                  echo "[ERROR] We currently only support: Debian 7,8,9 (testing) / Linux Mint Debian Edition (LMDE 2 Betsy) / Ubuntu Desktop 15.10+ and Devuan"
                  exit 1
               fi
            fi
         fi
      fi
   fi
fi
}

#// FUNCTION: check state (Version 1.0)
checkhard() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
   sleep 1
   exit 1
fi
}

#// FUNCTION: check state without exit (Version 1.0)
checksoft() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;33mFAILED\033[0m\n")] '"$@"'"
   sleep 1
fi
}

#// FUNCTION: check state hidden (Version 1.0)
checkhiddenhard() {
if [ $? -eq 0 ]
then
   return 0
else
   #/return 1
   checkhard "$@"
   return 1
fi
}

#// FUNCTION: check state hidden without exit (Version 1.0)
checkhiddensoft() {
if [ $? -eq 0 ]
then
   return 0
else
   #/return 1
   checksoft "$@"
   return 1
fi
}

#// FUNCTION: starting all lxc vms (Version 1.0)
lxcstartall() {
   for i in $(lxc-ls --stopped | egrep -v "managed|deb7template|deb8template")
   do
      if [ "$DEBIAN" = "ubuntu" ]
      then
         screen -d -m -S "$i" -- lxc-start -n "$i" -F
         (sleep 5) & spinner $!
      else
         screen -d -m -S "$i" -- lxc-start -n "$i"
         (sleep 5) & spinner $!
      fi
      lxc-ls --active | grep -sc "$i" > /dev/null 2>&1
      checksoft LXC-Start: "$i"
   done
}

#// FUNCTION: stopping lxc managed vm (Version 1.0)
lxcstopmanaged() {
   for i in $(lxc-ls --active | grep "managed")
   do
      (lxc-stop -n "$i") & spinner $!
      checksoft LXC-Stop: "$i"
      (sleep 1) & spinner $!
   done
}

#// FUNCTION: stopping all lxc vms (Version 1.0)
lxcstopall() {
   for i in $(lxc-ls --active | egrep -v "managed|deb7template|deb8template")
   do
      (lxc-stop -t 60 -n "$i") & spinner $!
      checkhiddensoft LXC killed: "$i"
      #/lxc-ls --stopped | grep -sc "$i" > /dev/null 2>&1
      checksoft LXC-Stop: "$i"
      (sleep 5) & spinner $!
   done
}

#// FUNCTION: clean up lxc portforwarding (Version 1.0)
cleanlxcportforwarding() {
   CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
   GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')
   CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
   if [ -e "$CHECKFORWARDINGFILE" ]
   then
      #// clean up old iptables nat rules inside lxc: managed
      lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -F; iptables -t nat -X '
      lxc-attach -n managed -- /bin/sh -c ' ip6tables -t nat -F; ip6tables -t nat -X '
      if [ "$CHECKENVIRONMENT" = "proxy" ]
      then
         #// clean up old iptables nat rules on HOST
         iptables -t nat -F; iptables -t nat -X
         ip6tables -t nat -F; ip6tables -t nat -X
      fi
   fi
checkhard lxc-to-go clean up portforwarding
}

#// FUNCTION: set up lxc portforwarding (version 1.2)
lxcportforwarding() {
   CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
   GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')
   CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
   if [ -e "$CHECKFORWARDINGFILE" ]
   then
      #// clean up old iptables nat rules inside lxc: managed
      lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -F; iptables -t nat -X '
      lxc-attach -n managed -- /bin/sh -c ' ip6tables -t nat -F; ip6tables -t nat -X '
      #// set up nat inside lxc: managed
      lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE '
      lxc-attach -n managed -- /bin/sh -c ' ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE '
      if [ "$CHECKENVIRONMENT" = "proxy" ]
      then
         #// clean up old iptables nat rules on HOST
         iptables -t nat -F; iptables -t nat -X
         ip6tables -t nat -F; ip6tables -t nat -X
         #// set up nat on HOST
         iptables -t nat -A POSTROUTING -o "$GETINTERFACE" -j MASQUERADE
         ip6tables -t nat -A POSTROUTING -o "$GETINTERFACE" -j MASQUERADE
      fi
# ipv4 //
      #/lxc-ls --active --fancy -F name,state,ipv4 | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | grep "192.168.254" | awk 'BEGIN{ORS=" "}{if($2 == "RUNNING"){fields=3;while(fields < NF){sub(/,$/,"",$fields);if(match($fields,/^192.168.254/) != 0){print $1,$2,$fields;break}fields=fields+1}}}' | awk '{print $1,$3}' | sed 's/,//' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp
      #// get ip list
      lxc-ls --active --fancy -F name,state,ipv4,ipv6 | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | grep "192.168.254" | awk '{if($2 == "RUNNING"){fields=3;while(fields < NF){sub(/,$/,"",$fields);if(match($fields,/^192.168.254/) != 0 || match($fields,/fd00:aaaa:254/) != 0){print $1,$2,$fields;break};fields=fields+1}}}' | awk '{print $1,$3}' | sed 's/,//' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp
      #// merge ipv4 list
      awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "192.168.254" > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.tmp
      #// convert ipv4 list
      cat /etc/lxc-to-go/tmp/lxc.ipv4.running.list.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.conv.tmp
      #// set ipv4 iptables rules inside lxc: managed
      #/(
      while read -r line
      do
         set -- $line
         #// add new port mapping
         if [ ! -z "$2" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}"
            checkhiddenhard lxc: set up nat rules
         fi
         ### set iptable rules on HOST // ###
         if [ "$CHECKENVIRONMENT" = "proxy" ]
         then
            #// add new port mapping
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
               checkhiddenhard lxc: set up nat rules
            if [ ! -z "$3" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$4" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$5" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$6" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$7" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$8" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$9" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${10}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${11}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${12}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${13}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${14}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${15}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${16}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${17}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${18}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${19}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${20}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${21}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}"
               checkhiddenhard lxc: set up nat rules
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}"
               checkhiddenhard lxc: set up nat rules
            fi
         fi
         ### // set iptable rules on HOST ###
      done < "/etc/lxc-to-go/tmp/lxc.ipv4.running.list.conv.tmp"
      #/)
      ### // set iptable rules ###
# // ipv4
# ipv6 //
      #/lxc-ls --active --fancy -F name,state,ipv6 | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | grep "fd00:aaaa:254" | awk 'BEGIN{ORS=" "}{if($2 == "RUNNING"){fields=3;while(fields < NF){sub(/,$/,"",$fields);if(match($fields,/^fd00:aaaa:254/) != 0){print $1,$2,$fields;break}fields=fields+1}}}' | awk '{print $1,$3}' | sed 's/,//' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv6.running.tmp
      #// get ip list
      lxc-ls --active --fancy -F name,state,ipv6,ipv4 | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | grep "fd00:aaaa:254" | awk '{if($2 == "RUNNING"){fields=3;while(fields < NF){sub(/,$/,"",$fields);if(match($fields,/^fd00:aaaa:254/) != 0 || match($fields,/192.168.254/) != 0){print $1,$2,$fields;break};fields=fields+1}}}' | awk '{print $1,$3}' | sed 's/,//' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv6.running.tmp
      #// merge ipv6 list
      awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv6.running.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/ ://' | grep "fd00:aaaa:254" > /etc/lxc-to-go/tmp/lxc.ipv6.running.list.tmp
      #// convert ipv6 list
      cat /etc/lxc-to-go/tmp/lxc.ipv6.running.list.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv6.running.list.conv.tmp
      #// set ipv6 iptables rules inside lxc: managed
      #/(
      while read -r line
      do
         set -- $line
         #// add new port mapping
         if [ ! -z "$2" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination ["$1"]:"$2"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination ["$1"]:"$2"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination ["$1"]:"$3"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination ["$1"]:"$3"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination ["$1"]:"$4"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination ["$1"]:"$4"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination ["$1"]:"$5"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination ["$1"]:"$5"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination ["$1"]:"$6"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination ["$1"]:"$6"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination ["$1"]:"$7"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination ["$1"]:"$7"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination ["$1"]:"$8"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination ["$1"]:"$8"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination ["$1"]:"$9"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination ["$1"]:"$9"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination ["$1"]:"${10}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination ["$1"]:"${10}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination ["$1"]:"${11}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination ["$1"]:"${11}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination ["$1"]:"${12}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination ["$1"]:"${12}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination ["$1"]:"${13}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination ["$1"]:"${13}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination ["$1"]:"${14}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination ["$1"]:"${14}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination ["$1"]:"${15}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination ["$1"]:"${15}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination ["$1"]:"${16}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination ["$1"]:"${16}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination ["$1"]:"${17}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination ["$1"]:"${17}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination ["$1"]:"${18}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination ["$1"]:"${18}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination ["$1"]:"${19}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination ["$1"]:"${19}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination ["$1"]:"${20}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination ["$1"]:"${20}"
            checkhiddenhard lxc: set up nat rules
         fi
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination ["$1"]:"${21}"
            checkhiddenhard lxc: set up nat rules
            lxc-attach -n managed -- ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination ["$1"]:"${21}"
            checkhiddenhard lxc: set up nat rules
         fi
         ### set iptable rules on HOST // ###
         if [ "$CHECKENVIRONMENT" = "proxy" ]
         then
            #// add new port mapping
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination [fd00:aaaa:253::254]:"$2"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination [fd00:aaaa:253::254]:"$2"
               checkhiddenhard lxc: set up nat rules
            if [ ! -z "$3" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination [fd00:aaaa:253::254]:"$3"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination [fd00:aaaa:253::254]:"$3"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$4" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination [fd00:aaaa:253::254]:"$4"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination [fd00:aaaa:253::254]:"$4"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$5" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination [fd00:aaaa:253::254]:"$5"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination [fd00:aaaa:253::254]:"$5"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$6" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination [fd00:aaaa:253::254]:"$6"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination [fd00:aaaa:253::254]:"$6"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$7" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination [fd00:aaaa:253::254]:"$7"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination [fd00:aaaa:253::254]:"$7"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$8" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination [fd00:aaaa:253::254]:"$8"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination [fd00:aaaa:253::254]:"$8"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "$9" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination [fd00:aaaa:253::254]:"$9"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination [fd00:aaaa:253::254]:"$9"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${10}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${10}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${10}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${11}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${11}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${11}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${12}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${12}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${12}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${13}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${13}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${13}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${14}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${14}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${14}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${15}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${15}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${15}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${16}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${16}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${16}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${17}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${17}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${17}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${18}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${18}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${18}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${19}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${19}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${19}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${20}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${20}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${20}"
               checkhiddenhard lxc: set up nat rules
            fi
            if [ ! -z "${21}" ]; then
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${21}"
               checkhiddenhard lxc: set up nat rules
               ip6tables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination [fd00:aaaa:253::254]:"${21}"
               checkhiddenhard lxc: set up nat rules
            fi
         fi
         ### // set iptable rules on HOST ###
      done < "/etc/lxc-to-go/tmp/lxc.ipv6.running.list.conv.tmp"
      #/)
      ### // set iptable rules ###
# // ipv6
   fi
checkhard lxc-to-go portforwarding
### // FORWARDING ###
}
### // stage0 ###

### stage1 // ###
if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
then
   : # dummy
else
   echo "[ERROR] Plattform = unknown"
   exit 1
fi
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhiddenhard lxc-to-go environment - stage 1
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
checkhiddenhard lxc-to-go environment - stage 2

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
checkhiddenhard lxc-to-go environment - stage 3

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### BTRFS SUPPORT // ###
GETBTRFS=$(grep -s "BTRFS" /etc/lxc-to-go/lxc-to-go.conf | sed 's/BTRFS=//')
### // BTRFS SUPPORT ###

### PROVISIONING // ###

while getopts ":n:t:h:p:s:" opt; do
  case "$opt" in
    n) name=$OPTARG ;;
    t) template=$OPTARG ;;
    h) hooks=$OPTARG ;;
    p) port=$OPTARG ;;
    s) start=$OPTARG ;;
  esac
done
shift $(( OPTIND - 1 ))

#/ show usage
if [ -z "$name" ]; then
   echo "" # dummy
   echo "usage:   ./lxc-to-go_provisioning.sh -n {name} -t {template} -h {hooks} -p {port} -s {start}"
   echo "example: -n example -t deb8 -h yes -p 60001,60002 -s yes"
   echo "" # dummy
   exit 0
fi
check lxc-to-go environment - stage 4

#/ check name - alphanumeric
cname="$(echo "$name" | sed -e 's/[^[:alnum:]]//g')"
if [ "$cname" != "$name" ] ; then
   echo "" # dummy
   echo "[ERROR] string -name '"$name"' has characters which are not alphanumeric"
   exit 1
fi
check lxc-to-go environment - stage 5

#/ check template - empty argument
if [ -z "$template" ]; then
   echo "" # dummy
   echo "[ERROR] choose for template argument (deb7/deb8)"
   exit 1
fi
check lxc-to-go environment - stage 6

#/ check template - argument
ctemplate="$(echo "$template" | sed 's/deb7//g' | sed 's/deb8//g')"
if [ -z "$ctemplate" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for template argument (deb7/deb8)"
   exit 1
fi
check lxc-to-go environment - stage 7

#/ check hooks - empty argument
if [ -z "$hooks" ]; then
   echo "" # dummy
   echo "[ERROR] choose for hooks argument (yes/no)"
   exit 1
fi
check lxc-to-go environment - stage 8

#/ check hooks - argument
chooks="$(echo "$hooks" | sed 's/yes//g' | sed 's/no//g')"
if [ -z "$chooks" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for hooks argument (yes/no)"
   exit 1
fi
check lxc-to-go environment - stage 9

#/ check port - empty argument
if [ -z "$port" ]; then
   echo "" # dummy
   echo "[ERROR] choose a port number or alternative use 'lxc-to-go create'"
   exit 1
fi
check lxc-to-go environment - stage 10

#/ check port - numeric
cport="$(echo "$port" | sed 's/[^0-9,]*//g')"
if [ "$cport" != "$port" ] ; then
   echo "" # dummy
   echo "[ERROR] string -port '"$port"' has characters which are not numeric"
   exit 1
fi
check lxc-to-go environment - stage 11

#/ check port - length
cportlength=$(echo -n "$port" | wc -c)
if [ "$cportlength" -gt 5 ]; then
   cportmulti1=$(echo "$port" | grep -c ",")
   if [ "$cportmulti1" = "1" ]; then
      : # dummy
   else
      echo "" # dummy
      echo "[ERROR] port number (up to 5 numbers) too long"
      exit 1
   fi
fi
check lxc-to-go environment - stage 12

cportmulti2=$(echo "$port" | grep -c ",")
if [ "$cportmulti2" = "1" ]; then
   : # dummy
else
   #/ check port - high
   if [ "$port" -gt 65535 ]; then
      echo "" # dummy
      echo "[ERROR] port number too high (1-65535 are available, and ports in range 1-1023 are the privileged ones)"
      exit 1
   fi
fi
check lxc-to-go environment - stage 13

CHECKPORTRESERVATION=$(grep -scw "$port" /etc/lxc-to-go/portforwarding.conf)
if [ "$CHECKPORTRESERVATION" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] port already reserved"
   exit 1
fi
check lxc-to-go environment - stage 14

#/ check start - empty argument
if [ -z "$start" ]; then
   echo "" # dummy
   echo "[ERROR] choose for start argument (yes/no)"
   exit 1
fi
check lxc-to-go environment - stage 15

#/ check start - argument
cstart="$(echo "$start" | sed 's/yes//g' | sed 's/no//g')"
if [ -z "$cstart" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for start argument (yes/no)"
   exit 1
fi
check lxc-to-go environment - stage 16

### create // ###

CHECKLXCEXIST=$(lxc-ls | grep -c "$name")
if [ "$CHECKLXCEXIST" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] lxc already exists!"
   exit 1
fi
check lxc-to-go environment - stage 17

###

if [ "$template" = "deb7" ]; then
   ### BTRFS SUPPORT // ###
   if [ "$GETBTRFS" = "yes" ]
   then
      (btrfs subvolume snapshot /var/lib/lxc/deb7template /var/lib/lxc/"$name") & spinner $!
      checksoft create new btrfs subvolume snapshot: "$name"
   else
      (lxc-clone -o deb7template -n "$name") & spinner $!
   fi
   ### // BTRFS SUPPORT ###
   if [ $? -eq 0 ]
   then
      : # dummy
   else
      echo "" # dummy
      echo "[ERROR] lxc-clone to "$name" failed!"
         lxc-stop -n "$name" -k
         lxc-destroy -n "$name"
      exit 1
   fi
   sed -i 's/deb7template/'"$name"'/g' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.veth.pair = deb7temp/lxc.network.veth.pair = '"$name"'/' /var/lib/lxc/"$name"/config
   sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   echo "$name" > /var/lib/lxc/"$name"/rootfs/etc/hostname
fi
check lxc-to-go provisioning - stage 1

if [ "$template" = "deb8" ]; then
   ### BTRFS SUPPORT // ###
   if [ "$GETBTRFS" = "yes" ]
   then
      (btrfs subvolume snapshot /var/lib/lxc/deb8template /var/lib/lxc/"$name") & spinner $!
      checksoft create new btrfs subvolume snapshot: "$name"
   else
      (lxc-clone -o deb8template -n "$name") & spinner $!
   fi
   ### // BTRFS SUPPORT ###
   if [ $? -eq 0 ]
   then
      : # dummy
   else
      echo "" # dummy
      echo "[ERROR] lxc-clone to "$name" failed!"
         lxc-destroy -n "$name"
      exit 1
   fi
   sed -i 's/deb8template/'"$name"'/g' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.veth.pair = deb8temp/lxc.network.veth.pair = '"$name"'/' /var/lib/lxc/"$name"/config
   sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   echo "$name" > /var/lib/lxc/"$name"/rootfs/etc/hostname
fi
check lxc-to-go provisioning - stage 2

### create // ###

CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')

### cleanup // ###
#
CHECKDEB7IF=$(ifconfig | grep -c "deb7temp")
if [ "$CHECKDEB7IF" = "1" ]; then
   ip link set dev deb7temp down
   ip link del deb7temp
fi
check lxc-to-go provisioning - stage 3

CHECKDEB8IF=$(ifconfig | grep -c "deb8temp")
if [ "$CHECKDEB8IF" = "1" ]; then
   ip link set dev deb8temp down
   ip link del deb8temp
fi
check lxc-to-go provisioning - stage 4
#
### // cleanup ###

### start // ###
if [ "$start" = "yes" ]; then
   #/screen -d -m -S "$name" -- lxc-start -n "$name"
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      screen -d -m -S "$name" -- lxc-start -n "$name" -F
   else
      screen -d -m -S "$name" -- lxc-start -n "$name"
   fi
### // fix
   echo "" # dummy
   echo "... starting screen session ..."
   sleep 2
   screen -list | grep "$name"
   echo "" # dummy
   (sleep 15) & spinner $!
   : # dummy
   if [ "$hooks" = "yes" ]; then
      LXCCREATENAME="$name"
      export LXCCREATENAME
      ###
         echo "" # dummy
            echo "$port" > /var/lib/lxc/"$name"/rootfs/root/PORT
            #/ $DIR/hooks/hook_provisioning.sh
            /etc/lxc-to-go/hook_provisioning.sh
            if [ $? -eq 0 ]
            then
               printf "\033[1;32m OK \033[0m\n"
               sleep 2
            else
               printf "\033[1;31m FAILED \033[0m\n"
               echo "... cleaning up and destroy the corrupt container!"
               lxc-stop -n "$name" -k
               sleep 1
               lxc-destroy -n "$name"
               exit 1
            fi
         echo "" # dummy
      ###
      unset LXCCREATENAME
   fi
fi
check lxc-to-go provisioning - stage 5

if [ "$start" = "no" ]; then
   if [ "$hooks" = "yes" ]; then
   #/screen -d -m -S "$name" -- lxc-start -n "$name"
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      screen -d -m -S "$name" -- lxc-start -n "$name" -F
   else
      screen -d -m -S "$name" -- lxc-start -n "$name"
   fi
### // fix
   echo "" # dummy
   echo "... starting screen session ..."
   sleep 2
   screen -list | grep "$name"
   echo "" # dummy
      LXCCREATENAME="$name"
      export LXCCREATENAME
      : # dummy
      echo "" # dummy
      (sleep 15) & spinner $!
      : # dummy
      ###
         echo "" # dummy
            echo "$port" > /var/lib/lxc/"$name"/rootfs/root/PORT
            #/ $DIR/hooks/hook_provisioning.sh
            /etc/lxc-to-go/hook_provisioning.sh
            if [ $? -eq 0 ]
            then
               printf "\033[1;32m OK \033[0m\n"
               sleep 2
            else
               printf "\033[1;31m FAILED \033[0m\n"
               echo "... cleaning up and destroy the corrupt container!"
               lxc-stop -n "$name" -k
               sleep 1
               lxc-destroy -n "$name"
               exit 1
            fi
         echo "" # dummy
      ###
      unset LXCCREATENAME
   fi
fi
check lxc-to-go provisioning - stage 6
### start // ###

### FORWARDING // ###
#
   echo "$name : $port" >> /etc/lxc-to-go/portforwarding.conf
#
CHECKFORWARDING=$(grep -s "$name" /etc/lxc-to-go/portforwarding.conf | awk '{print $3}')
if [ -z "$CHECKFORWARDING" ]; then
   : # dummy
else
   if [ "$start" = "yes" -o "$hooks" = "yes" ]; then
      echo "" # dummy
      echo "... activate FORWARDING ..."
      sleep 5
      GETIPV4=$(lxc-attach -n "$name" -- ifconfig eth0 | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      if [ -z "$GETIPV4" ]; then
         echo "[ERROR] Can't get IPv4 Address"
            lxc-stop -n "$name" -k
            lxc-destroy -n "$name"
         exit 1
      else
            lxcportforwarding
      fi
   fi
fi
check lxc-to-go portforwarding END
#
### // FORWARDING ###

### // PROVISIONING ###

### ### ###
echo ""
printf "\033[1;32mlxc-to-go provisioning finished.\033[0m\n"
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
