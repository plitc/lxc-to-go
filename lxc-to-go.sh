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
#
ADIR="$PWD"

#// FUNCTION: spinner
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

#// FUNCTION: clean up tmp files
cleanup() {
   rm -rf /etc/lxc-to-go/tmp/*
}

#// FUNCTION: run script as root
checkrootuser() {
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// FUNCTION: check debian based distributions
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

#// FUNCTION: check state
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

#// FUNCTION: check state without exit
checksoft() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
   sleep 1
fi
}

#// FUNCTION: starting all lxc vms
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

#// FUNCTION: stopping lxc managed vm
lxcstopmanaged() {
   for i in $(lxc-ls --active | grep "managed")
   do
      (lxc-stop -n "$i") & spinner $!
      checksoft LXC-Stop: "$i"
      (sleep 1) & spinner $!
   done
}

#// FUNCTION: stopping all lxc vms
lxcstopall() {
   for i in $(lxc-ls --active | egrep -v "managed|deb7template|deb8template")
   do
      (lxc-stop -n "$i") & spinner $!
      lxc-ls --stopped | grep -sc "$i" > /dev/null 2>&1
      checksoft LXC-Stop: "$i"
      (sleep 5) & spinner $!
   done
}

#// FUNCTION: set up lxc start portforwarding
lxcstartportforwarding() {
   CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
   if [ -e "$CHECKFORWARDINGFILE" ]
   then
      # ipv4 //
      lxc-ls --active --fancy | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | awk '{print $1,$3}' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp
      #// merge ipv4 list
      awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.tmp
      #// convert ipv4 list
      cat /etc/lxc-to-go/tmp/lxc.ipv4.running.list.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.conv.tmp
      #// set ipv4 iptables rules inside lxc: managed
      (
      while read -r line
      do
         set -- $line
         #// delete old port mapping
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$2"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$3"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$4"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$5"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$6"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$7"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$8"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$9"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$10"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$11"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$12"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$13"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$14"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$15"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$16"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$17"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$18"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$19"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$20"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- /bin/sh -c ' iptables -t nat -L --line-numbers | grep "dpt:'"$21"'" | awk {"print \$1"} | xargs -L 1 -I % iptables -t nat -D PREROUTING % ' > /dev/null 2>&1
         fi
         #// add new port mapping
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2"
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2"
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
         fi
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
         fi
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
         fi
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
         fi
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
         fi
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
         fi
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
         fi
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
         fi
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
         fi
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
         fi
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
         fi
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
         fi
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
         fi
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
         fi
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
         fi
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
         fi
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
         fi
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
         fi
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
         fi
         #
         CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
         GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')
         #
         ### set iptable rules on HOST // ###
         if [ "$CHECKENVIRONMENT" = "proxy" ]; then
            #// delete old port mapping
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
            if [ ! -z "$3" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
            fi
            if [ ! -z "$4" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
            fi
            if [ ! -z "$5" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
            fi
            if [ ! -z "$6" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
            fi
            if [ ! -z "$7" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
            fi
            if [ ! -z "$8" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
            fi
            if [ ! -z "$9" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
            fi
            if [ ! -z "${10}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
            fi
            if [ ! -z "${11}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
            fi
            if [ ! -z "${12}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
            fi
            if [ ! -z "${13}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
            fi
            if [ ! -z "${14}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
            fi
            if [ ! -z "${15}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
            fi
            if [ ! -z "${16}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
            fi
            if [ ! -z "${17}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
            fi
            if [ ! -z "${18}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
            fi
            if [ ! -z "${19}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
            fi
            if [ ! -z "${20}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
            fi
            if [ ! -z "${21}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
            fi
            #// add new port mapping
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
            if [ ! -z "$3" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
            fi
            if [ ! -z "$4" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
            fi
            if [ ! -z "$5" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
            fi
            if [ ! -z "$6" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
            fi
            if [ ! -z "$7" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
            fi
            if [ ! -z "$8" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
            fi
            if [ ! -z "$9" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
            fi
            if [ ! -z "${10}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
            fi
            if [ ! -z "${11}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
            fi
            if [ ! -z "${12}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
            fi
            if [ ! -z "${13}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
            fi
            if [ ! -z "${14}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
            fi
            if [ ! -z "${15}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
            fi
            if [ ! -z "${16}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
            fi
            if [ ! -z "${17}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
            fi
            if [ ! -z "${18}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
            fi
            if [ ! -z "${19}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
            fi
            if [ ! -z "${20}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
            fi
            if [ ! -z "${21}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
            fi
         fi
         ### // set iptable rules on HOST ###
      done < "/etc/lxc-to-go/tmp/lxc.ipv4.running.list.conv.tmp"
      )
      ### // set iptable rules ###
      # // ipv4
   fi
checkhard lxc-to-go portforwardingnew
### // FORWARDING ###
}



#// FUNCTION: set up lxc start portforwarding (old)
lxcstartportforwardingold() {
### FORWARDING // ###
#/echo "" # dummy
sleep 5
CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
if [ -e "$CHECKFORWARDINGFILE" ]; then
   # ipv4 //
   lxc-ls --active --fancy | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | awk '{print $1,$3}' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp
   #/ single port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | sed '/,/d' | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.s.tmp
   #/ multi port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.running.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "," | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.m.tmp
   #
   ### set iptable rules // ###
   #/ single port support
   (
   while read -r line
   do
      set -- $line
      #
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      #
      lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$3":"$2"
      lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$3":"$2"
      #
      CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
      #
      ### set iptable rules on HOST // ###
      if [ "$CHECKENVIRONMENT" = "proxy" ]; then
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
         #
         iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
         iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
      fi
      ### // set iptable rules on HOST ###
      #
   done < "/etc/lxc-to-go/tmp/lxc.ipv4.running.list.s.tmp"
   )
   #/ multi port support
   STARTMULTIPORTSUPPORTFILE="/etc/lxc-to-go/tmp/lxc.ipv4.running.list.m.tmp"
   if [ -z "$STARTMULTIPORTSUPPORTFILE" ]; then
      : # dummy
   else
      #/ dirty but functional (up to 20 ports)
      cat /etc/lxc-to-go/tmp/lxc.ipv4.running.list.m.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.running.list.m.dirty.tmp
      (
      while read -r line
      do
         set -- $line
         ###/ delete MPORTS /###
         #/ MPORT 1
         lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
         lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
         #/ MPORT 2
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
         fi
         #/ MPORT 3
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
         fi
         #/ MPORT 4
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
         fi
         #/ MPORT 5
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
         fi
         #/ MPORT 6
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
         fi
         #/ MPORT 7
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
         fi
         #/ MPORT 8
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
         fi
         #/ MPORT 9
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
         fi
         #/ MPORT 10
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
         fi
         #/ MPORT 11
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
         fi
         #/ MPORT 12
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
         fi
         #/ MPORT 13
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
         fi
         #/ MPORT 14
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
         fi
         #/ MPORT 15
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
         fi
         #/ MPORT 16
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
         fi
         #/ MPORT 17
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
         fi
         #/ MPORT 18
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
         fi
         #/ MPORT 19
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
         fi
         #/ MPORT 20
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
         fi
         ###/ add MPORTS /###
         #/ MPORT 1
         lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2"
         lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2"
         #/ MPORT 2
         if [ ! -z "$3" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
         fi
         #/ MPORT 3
         if [ ! -z "$4" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
         fi
         #/ MPORT 4
         if [ ! -z "$5" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
         fi
         #/ MPORT 5
         if [ ! -z "$6" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
         fi
         #/ MPORT 6
         if [ ! -z "$7" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
         fi
         #/ MPORT 7
         if [ ! -z "$8" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
         fi
         #/ MPORT 8
         if [ ! -z "$9" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
         fi
         #/ MPORT 9
         if [ ! -z "${10}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
         fi
         #/ MPORT 10
         if [ ! -z "${11}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
         fi
         #/ MPORT 11
         if [ ! -z "${12}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
         fi
         #/ MPORT 12
         if [ ! -z "${13}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
         fi
         #/ MPORT 13
         if [ ! -z "${14}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
         fi
         #/ MPORT 14
         if [ ! -z "${15}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
         fi
         #/ MPORT 15
         if [ ! -z "${16}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
         fi
         #/ MPORT 16
         if [ ! -z "${17}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
         fi
         #/ MPORT 17
         if [ ! -z "${18}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
         fi
         #/ MPORT 18
         if [ ! -z "${19}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
         fi
         #/ MPORT 19
         if [ ! -z "${20}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
         fi
         #/ MPORT 20
         if [ ! -z "${21}" ]; then
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
         fi
         #
         CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
         #
         ### set iptable rules on HOST // ###
         if [ "$CHECKENVIRONMENT" = "proxy" ]; then
            ###/ delete MPORTS /###
            #/ MPORT 1
            iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
            iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
            #/ MPORT 2
            if [ ! -z "$3" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
            fi
            #/ MPORT 3
            if [ ! -z "$4" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
            fi
            #/ MPORT 4
            if [ ! -z "$5" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
            fi
            #/ MPORT 5
            if [ ! -z "$6" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
            fi
            #/ MPORT 6
            if [ ! -z "$7" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
            fi
            #/ MPORT 7
            if [ ! -z "$8" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
            fi
            #/ MPORT 8
            if [ ! -z "$9" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
            fi
            #/ MPORT 9
            if [ ! -z "${10}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
            fi
            #/ MPORT 10
            if [ ! -z "${11}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
            fi
            #/ MPORT 11
            if [ ! -z "${12}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
            fi
            #/ MPORT 12
            if [ ! -z "${13}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
            fi
            #/ MPORT 13
            if [ ! -z "${14}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
            fi
            #/ MPORT 14
            if [ ! -z "${15}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
            fi
            #/ MPORT 15
            if [ ! -z "${16}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
            fi
            #/ MPORT 16
            if [ ! -z "${17}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
            fi
            #/ MPORT 17
            if [ ! -z "${18}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
            fi
            #/ MPORT 18
            if [ ! -z "${19}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
            fi
            #/ MPORT 19
            if [ ! -z "${20}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
            fi
            #/ MPORT 20
            if [ ! -z "${21}" ]; then
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
               iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
            fi
            ###/ add MPORTS /###
            #/ MPORT 1
            iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
            iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2"
            #/ MPORT 2
            if [ ! -z "$3" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
            fi
            #/ MPORT 3
            if [ ! -z "$4" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
            fi
            #/ MPORT 4
            if [ ! -z "$5" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
            fi
            #/ MPORT 5
            if [ ! -z "$6" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
            fi
            #/ MPORT 6
            if [ ! -z "$7" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
            fi
            #/ MPORT 7
            if [ ! -z "$8" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
            fi
            #/ MPORT 8
            if [ ! -z "$9" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
            fi
            #/ MPORT 9
            if [ ! -z "${10}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
            fi
            #/ MPORT 10
            if [ ! -z "${11}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
            fi
            #/ MPORT 11
            if [ ! -z "${12}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
            fi
            #/ MPORT 12
            if [ ! -z "${13}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
            fi
            #/ MPORT 13
            if [ ! -z "${14}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
            fi
            #/ MPORT 14
            if [ ! -z "${15}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
            fi
            #/ MPORT 15
            if [ ! -z "${16}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
            fi
            #/ MPORT 16
            if [ ! -z "${17}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
            fi
            #/ MPORT 17
            if [ ! -z "${18}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
            fi
            #/ MPORT 18
            if [ ! -z "${19}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
            fi
            #/ MPORT 19
            if [ ! -z "${20}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
            fi
            #/ MPORT 20
            if [ ! -z "${21}" ]; then
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
            fi
         fi
         ### // set iptable rules on HOST ###
         #
      done < "/etc/lxc-to-go/tmp/lxc.ipv4.running.list.m.dirty.tmp"
      )
   fi
   ### // set iptable rules ###
   # // ipv4
fi
checkhard lxc-to-go portforwarding
### // FORWARDING ###
}
### // stage0 ###

case "$1" in
'bootstrap')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
#/ fixes for lmde
if [ "$DEBIAN" = "linuxmint" ]
then
   if [ -e "/etc/lxc-to-go/INSTALLED" ]
   then
      : # dummy
   else
      #/ FIX: dirty dbus & systemd
      systemctl status >/dev/null 2>&1
      if [ $? -eq 0 ]
      then
         : dummy
      else
         apt-get update
         apt-get -y install --reinstall systemd-sysv
         echo "" # dummy
         printf "\033[1;31mWARNING: We fixed the SystemD Package Environment in your LMDE! Please Reboot your System immediately! and continue the bootstrap.\033[0m\n"
         echo "" # dummy
         exit 1
      fi
   fi
fi
checkhard optional: fixes for lmde
#
#/ fixes for ubuntu
if [ "$DEBIAN" = "ubuntu" ]
then
   systemctl stop apparmor
   systemctl disabpe apparmor >/dev/null 2>&1
   printf "\033[1;33mWARNING: disable AppArmor on Ubuntu!\033[0m\n"
   sleep 6
fi
checkhard optional: fixes for ubuntu
#
#/ fixes for devuan
if [ "$DEBIAN" = "devuan" ]
then
   : # dummy
   sleep 6
fi
checkhard optional: fixes for devuan
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

### WARNING // ###
if [ "$DEBVERSION" = "7" ]; then
   : # dummy
   CHECKLXCINSTALL0=$(/usr/bin/which lxc-checkconfig)
   if [ -z "$CHECKLXCINSTALL0" ]; then
      printf "\033[1;31mWARNING: lxc-to-go for wheezy is highly experimental and its not ready for production. Do it at your own risk.\033[0m\n"
      read -p "continue: (yes/no) ? " WARNINGDEB7
      if [ "$WARNINGDEB7" = "yes" ]; then
         : # dummy
      fi
      if [ "$WARNINGDEB7" = "no" ]; then
         echo "" # dummy
         echo "[ABORT]"
         exit 1
      fi
      if [ -z "$WARNINGDEB7" ]; then
         echo "" # dummy
         echo "[ABORT]"
         exit 1
      fi
   fi
fi
checkhard optional: debian wheezy upgrade information
### // WARNING ###

mkdir -p /etc/lxc-to-go
checkhard create lxc-to-go directory
mkdir -p /etc/lxc-to-go/tmp
checkhard create lxc-to-go/tmp directory

CHECKHOOKPROVISIONINGFILE="/etc/lxc-to-go/hook_provisioning.sh"
if [ -e "$CHECKHOOKPROVISIONINGFILE" ]; then
   : # dummy
else
   cp -prf "$DIR"/hooks/hook_provisioning.sh /etc/lxc-to-go/hook_provisioning.sh
fi
checkhard copy hook_provisioning.sh

CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
if [ -z "$CHECKENVIRONMENT" ]; then
   read -p "Choose your Environment: (bridge/proxy) ? " ENVIRONMENTVALUE
   if [ "$ENVIRONMENTVALUE" = "bridge" ]; then
   echo "ENVIRONMENT=bridge" > /etc/lxc-to-go/lxc-to-go.conf
   fi
   if [ "$ENVIRONMENTVALUE" = "proxy" ]; then
      echo "ENVIRONMENT=proxy" > /etc/lxc-to-go/lxc-to-go.conf
   fi
   if [ -z "$ENVIRONMENTVALUE" ]; then
      echo "[ERROR] choose an environment"
      exit 1
   fi
fi
checkhard lxc-to-go environment configcheck

GETENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')

CHECKINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')
if [ -z "$CHECKINTERFACE" ]; then
   read -p "Choose your Interface: (eth0/wlan0) ? " INTERFACEVALUE
   if [ -z "$INTERFACEVALUE" ]; then
      echo "[ERROR] choose an interface"
      exit 1
   fi
   CHECKINTERFACEVALUE=$(ifconfig | grep -c "$INTERFACEVALUE")
   if [ "$CHECKINTERFACEVALUE" = "0" ]; then
      echo "[ERROR] can't find the interface"
      exit 1
   fi
   echo "INTERFACE=$INTERFACEVALUE" >> /etc/lxc-to-go/lxc-to-go.conf
fi
checkhard lxc-to-go interface configcheck

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

#// fix: cgmanager dependency with systemd breaks devuan cgroups
if [ "$DEBIAN" = "devuan" ]
then
   printf "\033[1;33mWARNING: cgmanager dependency with systemd breaks devuan cgroups, so we ignore it!\033[0m\n"
else
   CGMANAGER=$(/usr/bin/which cgmanager)
   if [ -z "$CGMANAGER" ]; then
      echo "<--- --- --->"
      echo "need cgmanager"
      echo "<--- --- --->"
      apt-get update
      apt-get -y install cgmanager
      echo "<--- --- --->"
   fi
   checkhard look over cgmanager
fi

SCREEN=$(/usr/bin/which screen)
if [ -z "$SCREEN" ]; then
   echo "<--- --- --->"
   echo "need screen"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install screen
   echo "<--- --- --->"
fi
checkhard look over screen

IPTABLES=$(/usr/bin/which iptables)
if [ -z "$IPTABLES" ]; then
   echo "<--- --- --->"
   echo "need iptables"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install iptables
   echo "<--- --- --->"
fi
checkhard look over iptables

IP6TABLES=$(/usr/bin/which ip6tables)
if [ -z "$IP6TABLES" ]; then
   echo "<--- --- --->"
   echo "need ip6tables"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install ip6tables
   echo "<--- --- --->"
fi
checkhard look over ip6tables

LXC=$(/usr/bin/dpkg -l | grep lxc | awk '{print $2}')
if [ -z "$LXC" ]; then
   echo "<--- --- --->"
   echo "need lxc"
   echo "<--- --- --->"
   apt-get update
   DEBIAN_FRONTEND=noninteractive apt-get -y install lxc
   echo "<--- --- --->"
fi
checkhard look over lxc

DEBOOTSTRAP=$(/usr/bin/which debootstrap)
if [ -z "$DEBOOTSTRAP" ]; then
   echo "<--- --- --->"
   echo "need debootstrap"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install debootstrap
   echo "<--- --- --->"
fi
checkhard look over debootstrap

### LXC TEMPLATE - WHEEZY // ###
CHECKLXCTEMPLATEWHEEZY="/usr/share/lxc/templates/lxc-debian-wheezy"
if [ -e "$CHECKLXCTEMPLATEWHEEZY" ]; then
   : # dummy
else
   cp -prf /usr/share/lxc/templates/lxc-debian /usr/share/lxc/templates/lxc-debian-wheezy
   sed -i 's/release=${release:-${current_release}}/release=$(echo "wheezy")/g' /usr/share/lxc/templates/lxc-debian-wheezy
   #// BUG: E: Invalid Release file, no entry for main/binary-ppc/Packages
   #// FIX: for PowerPC Environment
   CHECKYABOOT0=$(/usr/bin/dpkg -l | grep yaboot | awk '{print $2}')
   if [ -z "$CHECKYABOOT0" ]
   then
      : # dummy
   else
      sed -i 's/debootstrap --verbose --variant=minbase --arch=$arch/debootstrap --verbose --variant=minbase --arch=powerpc/g' /usr/share/lxc/templates/lxc-debian-wheezy
   fi
fi
checkhard lxc template - wheezy configcheck
### // LXC TEMPLATE - WHEEZY ###

BRIDGEUTILS=$(/usr/bin/dpkg -l | grep bridge-utils | awk '{print $2}')
if [ -z "$BRIDGEUTILS" ]; then
   echo "<--- --- --->"
   echo "need bridge-utils"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install bridge-utils
   echo "<--- --- --->"
fi
checkhard look over bridge-utils

NETTOOLS=$(/usr/bin/dpkg -l | grep net-tools | awk '{print $2}')
if [ -z "$NETTOOLS" ]; then
   echo "<--- --- --->"
   echo "need net-tools"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install net-tools
   echo "<--- --- --->"
fi
checkhard look over net-tools

sleep 1

### LXC inside LXC // ###
CHECKLXCINSIDELXC=$(echo $container | grep -c "lxc")
### // LXC inside LXC ###

CHECKCGROUP=$(mount | grep -c "cgroup")
if [ "$CHECKCGROUP" -gt 0 ]
then
   : # dummy
   #// fixes for devuan
   if [ "$DEBIAN" = "devuan" ]
   then
      mount cgroup -t cgroup /sys/fs/cgroup >/dev/null 2>&1
   fi
else
   mount cgroup -t cgroup /sys/fs/cgroup >/dev/null 2>&1
fi

lxc-checkconfig
if [ $? -eq 0 ]
then
   : # dummy
else
    echo "[ERROR] lxc-checkconfig failed!"
    if [ "$CHECKLXCINSIDELXC" = "1" ]; then
       echo "" # dummy
       printf "\033[1;31m[ERROR] LXC inside LXC: copy your current kernel config (for example /boot/config-3.16.0-4-amd64) to your lxc-to-go container /boot directory\033[0m\n"
    fi
    exit 1
fi

sleep 1

### Wheezy KERNEL UPGRADE // ###
if [ "$DEBVERSION" = "7" ]; then
   CHECKDEB7KERNEL=$(grep -c "3.2" /proc/sys/kernel/osrelease)
   if [ "$CHECKDEB7KERNEL" = "1" ]; then
      CHECKDEB7KERNEL316=$(dpkg -l | grep -c "linux-headers-3.16")
      if [ "$CHECKDEB7KERNEL316" = "0" ]; then
         CHECKDEB7BACKPORTS=$(grep -r "wheezy-backports" /etc/apt/ | grep -c "wheezy-backports")
         if [ "$CHECKDEB7BACKPORTS" = "0" ]; then
            #/ echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/wheezy-backports.list
            #/ echo "deb-src http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list.d/wheezy-backports.list
/bin/cat << CHECKDEB7WHEEZYBACKPORTSFILE > /etc/apt/sources.list.d/wheezy-backports.list
### ### ### lxc-to-go // ### ### ###

deb http://ftp.debian.org/debian wheezy-backports main contrib non-free
deb-src http://ftp.debian.org/debian wheezy-backports main contrib non-free

### ### ### // lxc-to-go ### ### ###
# EOF
CHECKDEB7WHEEZYBACKPORTSFILE
         fi
         apt-get -y autoclean
         apt-get -y clean
         apt-get -y update
         ### Deb7 DIST-UPGRADE // ###
         apt-get -y upgrade
         apt-get -y dist-upgrade
         ### // Deb7 DIST-UPGRADE ###
         CHECKDEB7ARCH=$(arch)
         if [ "$CHECKDEB7ARCH" = "686" ]; then
            apt-get -y install initramfs-tools=0.115*
            apt-get -y install linux-image-3.16.0-0.bpo.4-686-pae linux-headers-3.16.0-0.bpo.4-686-pae
            apt-get -y install firmware-linux-nonfree
            CHECKDEB7VBOX=$(dpkg -l | grep -c "virtualbox-guest-dkms")
            if [ "$CHECKDEB7VBOX" = "1" ]; then
               apt-get -y install build-essential module-assistant
               m-a prepare
               apt-get -y install --reinstall virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11
               #/ apt-get -y install --reinstall virtualbox-guest-dkms
               apt-get -y install virtualbox-dkms -t wheezy-backports --no-install-recommends
            fi
         fi
         if [ "$CHECKDEB7ARCH" = "x86_64" ]; then
            apt-get -y install initramfs-tools=0.115*
            apt-get -y install linux-image-3.16.0-0.bpo.4-amd64 linux-headers-3.16.0-0.bpo.4-amd64
            apt-get -y install firmware-linux-nonfree
            CHECKDEB7VBOX=$(dpkg -l | grep -c "virtualbox-guest-dkms")
            if [ "$CHECKDEB7VBOX" = "1" ]; then
               apt-get -y install build-essential module-assistant
               m-a prepare
               apt-get -y install --reinstall virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11
               #/ apt-get -y install --reinstall virtualbox-guest-dkms
               apt-get -y install virtualbox-dkms -t wheezy-backports --no-install-recommends
            fi
         fi
      fi
   fi
fi
checkhard optional: wheezy kernel upgrade
### // Wheezy KERNEL UPGRADE ###

### Wheezy - Jessie LXC // ###
if [ "$DEBVERSION" = "7" ]; then
   CHECKDEB7JESSIELXC=$(grep -r "jessie" /etc/apt/sources.list* | grep -c "jessie")
   if [ "$CHECKDEB7JESSIELXC" = "0" ]; then
      mv -f /etc/apt/sources.list /etc/apt/sources.list_lxc-to-go_BK
/bin/cat << CHECKDEB7WHEEZYFILE > /etc/apt/sources.list.d/wheezy.list
### ### ### lxc-to-go // ### ### ###
deb http://ftp.de.debian.org/debian/ wheezy main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy main contrib non-free

deb http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free

deb http://ftp.de.debian.org/debian-security/ wheezy/updates main contrib non-free
deb-src http://ftp.de.debian.org/debian-security/ wheezy/updates main contrib non-free
### ### ### // lxc-to-go  ### ### ###
# EOF
CHECKDEB7WHEEZYFILE

/bin/cat << CHECKDEB7JESSIELXCFILE > /etc/apt/sources.list.d/jessie.list
### ### ### lxc-to-go // ### ### ###
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free

deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free

deb http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
deb-src http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
### ### ### // lxc-to-go  ### ### ###
# EOF
CHECKDEB7JESSIELXCFILE

      ### APT File // ###
      CHECKDEB7APTCONF="/etc/apt/apt.conf"
      if [ -e "$CHECKDEB7APTCONF" ]; then
         mv -f /etc/apt/apt.conf /etc/apt/apt.conf_lxc-to-go_BK
      fi
/bin/cat << CHECKDEB7APTFILE > /etc/apt/apt.conf
### ### ### lxc-to-go // ### ### ###

APT::Default-Release "wheezy";

### ### ### // lxc-to-go  ### ### ###
# EOF
CHECKDEB7APTFILE
      ### // APT File ###

      ### APT Pinning // ###
/bin/cat << CHECKDEB7PREFERENCESFILE > /etc/apt/preferences
### ### ### lxc-to-go // ### ### ###

Package: *
Pin: release n=wheezy
Pin-Priority: 900

Package: *
Pin: release n=wheezy-backports
Pin-Priority: 500

Package: *
Pin: release n=jessie
Pin-Priority: 100

Package: linux-image linux-headers linux-image-amd64 linux-image-amd64-dbg initramfs-tools firmware-linux-free firmware-linux-nonfree
Pin: release n=wheezy-backports
Pin-Priority: 999

Package: lxc
Pin: release n=jessie
Pin-Priority: 999

### ### ### // lxc-to-go  ### ### ###
# EOF
CHECKDEB7PREFERENCESFILE
      ### // APT Pinning ###

      apt-get -y autoclean
      apt-get -y clean
      apt-get -y update
      apt-get -y install --no-install-recommends --reinstall -t jessie lxc
   fi
fi
checkhard optional: wheezy lxc upgrade
### // Wheezy - Jessie LXC ###

##/ modify grub

if [ "$CHECKLXCINSIDELXC" = "1" ]; then
   : ### LXC inside LXC ###
else
   #// ignore PowerPC Environment
   CHECKYABOOT1=$(/usr/bin/dpkg -l | grep yaboot | awk '{print $2}')
   if [ -z "$CHECKYABOOT1" ]
   then
      CHECKGRUB1=$(grep "GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "cgroup_enable=memory" | grep -c "swapaccount=1")
      if [ "$CHECKGRUB1" = "1" ]; then
         : # dummy
      else
         cp -prfv /etc/default/grub /etc/default/grub_lxc-to-go_BK
         sed -i '/GRUB_CMDLINE_LINUX=/s/.$//' /etc/default/grub
         sed -i '/GRUB_CMDLINE_LINUX=/s/$/ cgroup_enable=memory swapaccount=1"/' /etc/default/grub

         ### grub update

         : # dummy
         sleep 2
         grub-mkconfig
         : # dummy
         sleep 2
         update-grub
         if [ "$?" != "0" ]; then
            : # dummy
            sleep 5
            echo "[ERROR] something goes wrong let's restore the old configuration!" 1>&2
            cp -prfv /etc/default/grub_lxc-to-go_BK /etc/default/grub
            : # dummy
            sleep 2
            grub-mkconfig
            : # dummy
            sleep 2
            update-grub
            exit 1
         fi
         : # dummy
         touch /etc/lxc-to-go/STAGE1
         echo "" # dummy
         printf "\033[1;31mStage 1 finished. Please Reboot your System immediately! and continue the bootstrap\033[0m\n"
         exit 0
      fi
   fi
fi
checkhard grub configcheck

#// ignore PowerPC Environment
CHECKYABOOT2=$(/usr/bin/dpkg -l | grep yaboot | awk '{print $2}')
if [ -z "$CHECKYABOOT2" ]
then
   CHECKGRUB2=$(grep "cgroup_enable=memory" /proc/cmdline | grep -c "swapaccount=1")
   if [ "$CHECKGRUB2" = "1" ]; then
      : # dummy
   else
      : # dummy
      touch /etc/lxc-to-go/STAGE1
      echo "" # dummy
      printf "\033[1;31mStage 1 finished. Please Reboot your System immediately! and continue the bootstrap\033[0m\n"
      exit 0
   fi
fi
checkhard optional: powerpc environment configcheck

##/ check ip_tables/ip6_tables kernel module

if [ "$CHECKLXCINSIDELXC" = "1" ]; then
   : ### LXC inside LXC ###
else
   CHECKIPTABLES=$(lsmod | awk '{print $1}' | grep -c "ip_tables")
   if [ "$CHECKIPTABLES" = "1" ]; then
      : # dummy
   else
      modprobe ip_tables
   fi

   CHECKIP6TABLES=$(lsmod | awk '{print $1}' | grep -c "ip6_tables")
   if [ "$CHECKIP6TABLES" = "1" ]; then
      : # dummy
   else
      modprobe ip6_tables
   fi
fi
checkhard modprobe: iptables

CREATEBRIDGE0=$(ip a | grep -c "vswitch0:")
if [ "$CREATEBRIDGE0" = "1" ]; then
    : # dummy
else
   brctl addbr vswitch0

   #/if [ "$GETENVIRONMENT" = "bridge" ]; then
   #/ip link add dummy0 type dummy >/dev/null 2>&1
   #/brctl addif vswitch0 dummy0
   #/fi

   ##/ check lxc-to-go-ci
   CHECKLXCTOGOCI=$(basename $0)
   if [ "$CHECKLXCTOGOCI" = "lxc-to-go-ci.sh" ];then
      UDEVNET="/etc/udev/rules.d/70-persistent-net.rules"
      if [ -e "$UDEVNET" ]; then
         GETBRIDGEPORT0=$(grep -s 'SUBSYSTEM=="net"' /etc/udev/rules.d/70-persistent-net.rules | grep "eth" | head -n 1 | tr ' ' '\n' | grep "NAME" | sed 's/NAME="//' | sed 's/"//')
         if [ "$GETENVIRONMENT" = "bridge" ]; then
            brctl addif vswitch0 "$GETBRIDGEPORT0"
         fi
            sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".forwarding=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf."$GETBRIDGEPORT0".forwarding=1 >/dev/null 2>&1
         if [ "$GETENVIRONMENT" = "proxy" ]; then
         ### Proxy_ARP/NDP // ###
            sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".proxy_arp=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf."$GETBRIDGEPORT0".proxy_ndp=1 >/dev/null 2>&1
         ### // Proxy_ARP/NDP ###
         fi
      else
         if [ "$GETENVIRONMENT" = "bridge" ]; then
            brctl addif vswitch0 "$GETINTERFACE"
         fi
            sysctl -w net.ipv4.conf."$GETINTERFACE".forwarding=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf."$GETINTERFACE".forwarding=1 >/dev/null 2>&1
         if [ "$GETENVIRONMENT" = "proxy" ]; then
         ### Proxy_ARP/NDP // ###
            sysctl -w net.ipv4.conf."$GETINTERFACE".proxy_arp=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf."$GETINTERFACE".proxy_ndp=1 >/dev/null 2>&1
         ### // Proxy_ARP/NDP ###
         fi
      fi
   else
      if [ "$GETENVIRONMENT" = "bridge" ]; then
         brctl addif vswitch0 "$GETINTERFACE"
      fi
         sysctl -w net.ipv4.conf."$GETINTERFACE".forwarding=1 >/dev/null 2>&1
         sysctl -w net.ipv6.conf."$GETINTERFACE".forwarding=1 >/dev/null 2>&1
      if [ "$GETENVIRONMENT" = "proxy" ]; then
      ### Proxy_ARP/NDP // ###
         sysctl -w net.ipv4.conf."$GETINTERFACE".proxy_arp=1 >/dev/null 2>&1
         sysctl -w net.ipv6.conf."$GETINTERFACE".proxy_ndp=1 >/dev/null 2>&1
      ### // Proxy_ARP/NDP ###
      fi
   fi
      sysctl -w net.ipv4.conf.vswitch0.forwarding=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.vswitch0.forwarding=1 >/dev/null 2>&1
   if [ "$GETENVIRONMENT" = "proxy" ]; then
   ### Proxy_ARP/NDP // ###
      sysctl -w net.ipv4.conf.vswitch0.proxy_arp=1 >/dev/null 2>&1
      sysctl -w net.ipv6.conf.vswitch0.proxy_ndp=1 >/dev/null 2>&1
   ### // Proxy_ARP/NDP ###
   ### NAT // ###
      ##/ ipv4 nat
      iptables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
      iptables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
      iptables -t nat -A POSTROUTING -o "$GETINTERFACE" -j MASQUERADE
      ##/ ipv6 nat
      ip6tables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
      ip6tables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
      ip6tables -t nat -A POSTROUTING -o "$GETINTERFACE" -j MASQUERADE
      #/iptables -A FORWARD -i vswitch0 -j ACCEPT
      #/sysctl -w net.ipv4.conf.all.forwarding=1 >/dev/null 2>&1
      ### NDP // ###
      sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1
      ### // NDP ###
      ### # EXAMPLE #/ lxc1
      ### # EXAMPLE #/ iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport 10001 -j DNAT --to-destination 192.168.253.254:10001
      ### # EXAMPLE #/ iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport 10001 -j DNAT --to-destination 192.168.253.254:10001
   ### // NAT ###
   fi
fi
checkhard prepare bridge zones - stage 1

### NEW IP - Bridge Environment // ###
if [ "$GETENVIRONMENT" = "bridge" ]; then
   : # dummy
   ##/ ipv4
   #/killall dhclient
   if [ -e "$UDEVNET" ]; then
      #/dhclient "$GETBRIDGEPORT0" >/dev/null 2>&1
      #/route del default dev "$GETBRIDGEPORT0" >/dev/null 2>&1
      if [ "$DEBVERSION" = "7" ]; then
         pgrep -f "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBVERSION" = "8" ]; then
         ps -ax | grep "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBTESTVERSION" = "1" ]; then
         ps -ax | grep "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      ip addr flush "$GETBRIDGEPORT0"
      echo "" # dummy
      echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT $GETBRIDGEPORT0"
   else
      #/dhclient "$GETINTERFACE" >/dev/null 2>&1
      #/route del default dev "$GETINTERFACE" >/dev/null 2>&1
      if [ "$DEBVERSION" = "7" ]; then
         pgrep -f "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBVERSION" = "8" ]; then
         ps -ax | grep "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBTESTVERSION" = "1" ]; then
         ps -ax | grep "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      ip addr flush "$GETINTERFACE"
      echo "" # dummy
      echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT '"$GETINTERFACE"'"
   fi
   dhclient vswitch0 >/dev/null 2>&1
### fix //
   CHECKGETIPV4DEFAULTGATEWAY3=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
   if [ "$CHECKGETIPV4DEFAULTGATEWAY3" = "2" ]; then
      route del default
   fi
### // fix
   ##/ ipv6
   if [ -e "$UDEVNET" ]; then
      #/ifconfig "$GETBRIDGEPORT0" | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I % ifconfig vswitch0 inet6 add % >/dev/null 2>&1
      ip -6 route del ::/0 >/dev/null 2>&1
      echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
   else
      #/ifconfig "$GETINTERFACE" | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I % ifconfig vswitch0 inet6 add % >/dev/null 2>&1
      ip -6 route del ::/0 >/dev/null 2>&1
      echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
   fi
   ##/ container
   #/lxc-attach -n managed -- pkill dhclient
   lxc-attach -n managed -- killall dhclient >/dev/null 2>&1
   lxc-attach -n managed -- ip addr flush eth0 >/dev/null 2>&1
   lxc-attach -n managed -- dhclient eth0 >/dev/null 2>&1
   lxc-attach -n managed -- ip -6 route del ::/0 >/dev/null 2>&1
   lxc-attach -n managed -- echo "2" > /proc/sys/net/ipv6/conf/eth0/accept_ra >/dev/null 2>&1
   ### rc.local reload // ###
   lxc-attach -n managed -- /etc/rc.local >/dev/null 2>&1
   echo "" > /dev/null 2>&1 # dummy (workaround for rc.local check failed)
   ### // rc.local reload ###
fi
checkhard prepare bridge zones - stage 2
### // NEW IP - Bridge Environment ###

### NEW IP - Proxy Environment // ###
if [ "$GETENVIRONMENT" = "proxy" ]; then
   ##/ ipv4
   netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | xargs -L1 -I % echo "IPV4DEFAULTGATEWAY=%" > /tmp/lxc-to-go_IPV4GATEWAY.log
   chmod 0700 /tmp/lxc-to-go_IPV4GATEWAY.log
   if [ -e "$UDEVNET" ]; then
      GETIPV4UDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNETUDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep "255.255.255" | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ip addr flush vswitch0
      ip link set dev vswitch0 up > /dev/null 2>&1
      #/ifconfig vswitch0 inet "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV"
      ip addr add "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV" dev vswitch0
### fix //
      if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
      then
         ip addr del "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV" dev vswitch0
      fi
### // fix
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         ip addr add 192.168.253.253/24 dev vswitch0
      fi
### fix //
      CHECKGETIPV4DEFAULTGATEWAY1=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
      if [ "$CHECKGETIPV4DEFAULTGATEWAY1" = "2" ]; then
          #/route del default
          : # dummy
      fi
### // fix
   else
      GETIPV4=$(ifconfig "$GETINTERFACE" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNET=$(ifconfig "$GETINTERFACE" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep "255.255.255" | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ip addr flush vswitch0
      ip link set dev vswitch0 up > /dev/null 2>&1
      #/ifconfig vswitch0 inet "$GETIPV4"/"$GETIPV4SUBNET"
      ip addr add "$GETIPV4"/"$GETIPV4SUBNET" dev vswitch0
### fix //
      if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
      then
         ip addr del "$GETIPV4"/"$GETIPV4SUBNET" dev vswitch0
      fi
### // fix
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         ip addr add 192.168.253.253/24 dev vswitch0
      fi
### fix //
      CHECKGETIPV4DEFAULTGATEWAY2=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
      if [ "$CHECKGETIPV4DEFAULTGATEWAY2" = "2" ]; then
         #/route del default
         : # dummy
      fi
### // fix
   fi
   ### ### ###
   ##/ ipv6
   if [ "$GETENVIRONMENT" = "proxy" ]; then
      netstat -rn6 | grep "^::/0" | egrep -v "lo" | awk '{print $2}' | xargs -L1 -I % echo "IPV6DEFAULTGATEWAY=%" > /tmp/lxc-to-go_IPV6GATEWAY.log
      chmod 0700 /tmp/lxc-to-go_IPV6GATEWAY.log
      if [ -e "$UDEVNET" ]; then
         GETIPV6UDEV=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/\/.*$//')
         GETIPV6SUBNETUDEV=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/.*\///')
         ip -6 addr add "$GETIPV6UDEV"/"$GETIPV6SUBNETUDEV" dev vswitch0 >/dev/null 2>&1
### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            ip -6 addr del "$GETIPV6UDEV"/"$GETIPV6SUBNETUDEV" dev vswitch0 >/dev/null 2>&1
         fi
### // fix
         if [ "$GETENVIRONMENT" = "proxy" ]; then
            ip -6 addr add fd00:aaaa:253::253/64 dev vswitch0 >/dev/null 2>&1
         fi
### fix //
         GETIPV6UDEVLL1=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | grep "fe80" | head -n 1 | sed 's/\/.*$//')
         ip -6 addr add "$GETIPV6UDEVLL1"/64 dev vswitch0 >/dev/null 2>&1
   ### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            #// need link local!
            #/ip -6 addr del "$GETIPV6UDEVLL1"/64 dev vswitch0 >/dev/null 2>&1
            : # dummy
         fi
   ### // fix
### // fix
      else
         GETIPV6=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/\/.*$//')
         GETIPV6SUBNET=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/.*\///')
         ip -6 addr add "$GETIPV6"/"$GETIPV6SUBNET" dev vswitch0 >/dev/null 2>&1
### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            ip -6 addr del "$GETIPV6"/"$GETIPV6SUBNET" dev vswitch0 >/dev/null 2>&1
         fi
### // fix
         if [ "$GETENVIRONMENT" = "proxy" ]; then
            ip -6 addr add fd00:aaaa:253::253/64 dev vswitch0 >/dev/null 2>&1
         fi
### fix //
         GETIPV6LL1=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | grep "fe80" | head -n 1 | sed 's/\/.*$//')
         ip -6 addr add "$GETIPV6LL1"/64 dev vswitch0 >/dev/null 2>&1
   ### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            #/ need link local!
            #/ip -6 addr del "$GETIPV6LL1"/64 dev vswitch0 >/dev/null 2>&1
            : # dummy
         fi
   ### // fix
### // fix
      fi
      ### ### ###
      ##/ container
      ### rc.local reload // ###
      CHECKBOOTSTRAPINSTALL01="/etc/lxc-to-go/INSTALLED"
      if [ -e "$CHECKBOOTSTRAPINSTALL01" ]; then
         : # dummy
      else
         lxc-attach -n managed -- /etc/rc.local >/dev/null 2>&1
         echo "" > /dev/null 2>&1 # dummy (workaround for rc.local check failed)
      fi
      ### // rc.local reload ###
   fi
fi
checkhard prepare bridge zones - stage 3
### // NEW IP - Proxy Environment ###

### ### ###
sleep 1
### ### ###

### NEW 'managed' lxc bootstrap // ###
CHECKBOOTSTRAPINSTALL0="/etc/lxc-to-go/STAGE1"
if [ -e "$CHECKBOOTSTRAPINSTALL0" ]; then
   rm -f /etc/lxc-to-go/STAGE1
else
   CHECKBOOTSTRAPINSTALL1="/etc/lxc-to-go/INSTALLED"
   if [ -e "$CHECKBOOTSTRAPINSTALL1" ]; then
      : # dummy
   else
      #/ echo '[ERROR] previous "managed" lxc container bootstrap goes wrong'
      printf "\033[1;31m[ERROR] previous managed lxc container bootstrap goes wrong\033[0m\n"
      echo "" # dummy
      read -p "Do you wish to remove and cleanup the corrupt lxc-to-go environment and start again ? (y/n) " BOOTSTRAPCLEAN
      if [ "$BOOTSTRAPCLEAN" = "y" ]; then
         rm -f /etc/lxc-to-go/INSTALLED
         lxc-stop -n managed -k
         lxc-destroy -n managed
         lxc-destroy -n deb7template
         lxc-destroy -n deb8template
      fi
      sleep 1
      echo "" # dummy
   fi
fi
checkhard lxc: managed bootstrap - stage 1
### // NEW 'managed' lxc bootstrap ###

CHECKLXCMANAGED=$(lxc-ls | grep -c "managed")
if [ "$CHECKLXCMANAGED" = "1" ]; then
    : # dummy
else
   lxc-create -n managed -t /usr/share/lxc/templates/lxc-debian-wheezy
   if [ "$?" != "0" ]; then
      : # dummy
      echo '[ERROR] create "managed" lxc container failed'
      : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-destroy -n managed
         fi
      exit 1
   fi
fi
checkhard lxc: managed bootstrap - stage 2

CREATEBRIDGE1=$(ip a | grep -c "vswitch1:")
if [ "$CREATEBRIDGE1" = "1" ]; then
    : # dummy
else
   brctl addbr vswitch1
   ip link set dev vswitch1 up
   sysctl -w net.ipv4.conf.vswitch1.forwarding=1 >/dev/null 2>&1
   sysctl -w net.ipv6.conf.vswitch1.forwarding=1 >/dev/null 2>&1
fi
checkhard configure host sysctl

touch /etc/lxc/fstab.empty

LXCCONFIGFILEMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/config | awk '{print $4}' | head -n 1)
if [ X"$LXCCONFIGFILEMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
   if [ "$GETENVIRONMENT" = "bridge" ]; then
      : # dummy
/bin/cat << LXCCONFIGMANAGED1 > /var/lib/lxc/managed/config
### ### ### lxc-to-go // ### ### ###

lxc.utsname=managed

# vswitch0 / untagged
lxc.network.type=veth
lxc.network.link=vswitch0
lxc.network.name=eth0
lxc.network.hwaddr=aa:bb:c0:0c:bb:aa
lxc.network.veth.pair=managed
lxc.network.flags=up

# vswitch1 / intern
lxc.network.type=veth
lxc.network.link=vswitch1
lxc.network.name=eth1
lxc.network.veth.pair=managed1
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.254.254/24
#/ lxc.network.ipv4.gateway = auto
lxc.network.ipv6 = fd00:aaaa:0254::254/64
###

lxc.mount=/etc/lxc/fstab.empty
lxc.rootfs=/var/lib/lxc/managed/rootfs

# mounts point
lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry = sysfs sys sysfs defaults  0 0

#/ lxc.cgroup.memory.limit_in_bytes=268435456
#/ lxc.cgroup.memory.memsw.limit_in_bytes=268435456

### default ### lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config
#/ lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config

#
### LXC - jessie/systemd hacks // ###
lxc.autodev = 1
lxc.kmsg = 0

#!# lxc.cap.drop = sys_admin
#!# lxc.cap.drop = mknod
#!# lxc.cap.drop = audit_control
#!# lxc.cap.drop = audit_write
#!# lxc.cap.drop = setfcap
#!# lxc.cap.drop = setpcap
#!# lxc.cap.drop = sys_resource
#
lxc.cap.drop = sys_module
lxc.cap.drop = mac_admin
lxc.cap.drop = mac_override
lxc.cap.drop = sys_time
lxc.cap.drop = sys_boot
lxc.cap.drop = sys_pacct
lxc.cap.drop = sys_rawio
lxc.cap.drop = sys_tty_config

lxc.tty=2
lxc.pts = 1024
#/ lxc.mount.entry = /run/systemd/journal mnt/journal none bind,ro,create=dir 0 0
### // LXC - jessie/systemd hacks ###
#

lxc.cgroup.devices.deny = a
# tty
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# console
lxc.cgroup.devices.allow = c 5:1 rwm
# ptmx
lxc.cgroup.devices.allow = c 5:2 rwm
# pts/*
lxc.cgroup.devices.allow = c 136:* rwm
# null
lxc.cgroup.devices.allow = c 1:3 rwm
# zero
lxc.cgroup.devices.allow = c 1:5 rwm
# full
lxc.cgroup.devices.allow = c 1:7 rwm
# random
lxc.cgroup.devices.allow = c 1:8 rwm
# urandom
lxc.cgroup.devices.allow = c 1:9 rwm
# fuse
lxc.cgroup.devices.allow = c 10:229 rwm
# tun
lxc.cgroup.devices.allow = c 10:200 rwm

### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGED1

      #/if [ "$DEBVERSION" = "7" ]; then
      #/   sed -i '/lxc.autodev/d' /var/lib/lxc/managed/config
      #/   sed -i '/lxc.kmsg/d' /var/lib/lxc/managed/config
      #/fi

      ### randomized MAC address // ###
      RANDOM1=$(shuf -i 10-99 -n 1)
      RANDOM2=$(shuf -i 10-99 -n 1)
      sed -i 's/aa:bb:c0:0c:bb:aa/aa:bb:'"$RANDOM1"':'"$RANDOM2"':bb:aa/' /var/lib/lxc/managed/config
      ### // randomized MAC address ###

/bin/cat << CHECKMANAGEDNETFILE1 > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
iface eth0 inet6 auto

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE1
### ### ###
#
### randomized MAC address // ###

### randomized MAC address // ###
   fi
   if [ "$GETENVIRONMENT" = "proxy" ]; then
      : # dummy
/bin/cat << LXCCONFIGMANAGED2 > /var/lib/lxc/managed/config
### ### ### lxc-to-go // ### ### ###

lxc.utsname=managed

# vswitch0 / untagged
lxc.network.type=veth
lxc.network.link=vswitch0
lxc.network.name=eth0
lxc.network.hwaddr=aa:bb:c0:0c:bb:aa
lxc.network.veth.pair=managed
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.253.254/24
lxc.network.ipv4.gateway = 192.168.253.253
lxc.network.ipv6 = fd00:aaaa:0253::254/64
lxc.network.ipv6.gateway = fd00:aaaa:0253::253
###

# vswitch1 / intern
lxc.network.type=veth
lxc.network.link=vswitch1
lxc.network.name=eth1
lxc.network.veth.pair=managed1
lxc.network.flags=up
###
lxc.network.ipv4 = 192.168.254.254/24
#/ lxc.network.ipv4.gateway = auto
lxc.network.ipv6 = fd00:aaaa:0254::254/64
###

lxc.mount=/etc/lxc/fstab.empty
lxc.rootfs=/var/lib/lxc/managed/rootfs

# mounts point
lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
lxc.mount.entry = sysfs sys sysfs defaults  0 0

#/ lxc.cgroup.memory.limit_in_bytes=268435456
#/ lxc.cgroup.memory.memsw.limit_in_bytes=268435456

### default ### lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config
#/ lxc.cap.drop=audit_control audit_write mac_admin mac_override mknod setfcap setpcap sys_boot sys_module sys_pacct sys_rawio sys_resource sys_time sys_tty_config

#
### LXC - jessie/systemd hacks // ###
lxc.autodev = 1
lxc.kmsg = 0

#!# lxc.cap.drop = sys_admin
#!# lxc.cap.drop = mknod
#!# lxc.cap.drop = audit_control
#!# lxc.cap.drop = audit_write
#!# lxc.cap.drop = setfcap
#!# lxc.cap.drop = setpcap
#!# lxc.cap.drop = sys_resource
#
lxc.cap.drop = sys_module
lxc.cap.drop = mac_admin
lxc.cap.drop = mac_override
lxc.cap.drop = sys_time
lxc.cap.drop = sys_boot
lxc.cap.drop = sys_pacct
lxc.cap.drop = sys_rawio
lxc.cap.drop = sys_tty_config

lxc.tty=2
lxc.pts = 1024
#/ lxc.mount.entry = /run/systemd/journal mnt/journal none bind,ro,create=dir 0 0
### // LXC - jessie/systemd hacks ###
#

lxc.cgroup.devices.deny = a
# tty
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# console
lxc.cgroup.devices.allow = c 5:1 rwm
# ptmx
lxc.cgroup.devices.allow = c 5:2 rwm
# pts/*
lxc.cgroup.devices.allow = c 136:* rwm
# null
lxc.cgroup.devices.allow = c 1:3 rwm
# zero
lxc.cgroup.devices.allow = c 1:5 rwm
# full
lxc.cgroup.devices.allow = c 1:7 rwm
# random
lxc.cgroup.devices.allow = c 1:8 rwm
# urandom
lxc.cgroup.devices.allow = c 1:9 rwm
# fuse
lxc.cgroup.devices.allow = c 10:229 rwm
# tun
lxc.cgroup.devices.allow = c 10:200 rwm

### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGED2

/bin/cat << LXCCONFIGMANAGEDRESOLV > /var/lib/lxc/managed/rootfs/etc/resolv.conf
### ### ### lxc-to-go // ### ### ###
domain privat.local
search privat.local
nameserver 74.82.42.42
### ### ### // lxc-to-go ### ### ###
# EOF
LXCCONFIGMANAGEDRESOLV

      #/ if [ "$DEBVERSION" = "7" ]; then
      #/    sed -i '/lxc.autodev/d' /var/lib/lxc/managed/config
      #/    sed -i '/lxc.kmsg/d' /var/lib/lxc/managed/config
      #/ fi

/bin/cat << CHECKMANAGEDNETFILE2 > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
iface eth0 inet6 manual

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE2
   fi
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      sed -i '/lxc.cgroup.devices/d' /var/lib/lxc/managed/config
      sed -i '/lxc.mount.entry/d' /var/lib/lxc/managed/config
      echo "### fixes for ubuntu // ###" >> /var/lib/lxc/managed/config
      echo "#" >> /var/lib/lxc/managed/config
      echo "lxc.include = /usr/share/lxc/config/ubuntu.common.conf" >> /var/lib/lxc/managed/config
      echo "#" >> /var/lib/lxc/managed/config
      echo "### // fixes for ubuntu ###" >> /var/lib/lxc/managed/config
   fi
### // fix
fi
checkhard optional: fixes for ubuntu

CHECKTEMPLATEDEB7=$(lxc-ls | grep -c "deb7template")
if [ "$CHECKTEMPLATEDEB7" = "1" ]; then
   : # dummy
else
   echo "" # dummy
   if [ "$DEBVERSION" = "7" ]; then
      (lxc-clone -o managed -n deb7template) & spinner $!
   else
      (lxc-clone -M -B dir -o managed -n deb7template) & spinner $!
   fi
   sed -i '/lxc.network.ipv4/d' /var/lib/lxc/deb7template/config
   sed -i '/lxc.network.ipv6/d' /var/lib/lxc/deb7template/config
   sed -i '0,/lxc.network.type = veth/s/lxc.network.type = veth//' /var/lib/lxc/deb7template/config
   sed -i '0,/lxc.network.flags = up/s/lxc.network.flags = up//' /var/lib/lxc/deb7template/config
   sed -i '0,/lxc.network.link = vswitch0/s/lxc.network.link = vswitch0//' /var/lib/lxc/deb7template/config
   sed -i '0,/lxc.network.name = eth0/s/lxc.network.name = eth0//' /var/lib/lxc/deb7template/config
   sed -i '0,/lxc.network.veth.pair = managed/s/lxc.network.veth.pair = managed//' /var/lib/lxc/deb7template/config
   #/ sed -i '0,/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa/s/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa//' /var/lib/lxc/deb7template/config
   sed -i '/lxc.network.hwaddr/d' /var/lib/lxc/deb7template/config
   sed -i 's/managed1/deb7temp/g' /var/lib/lxc/deb7template/config
   sed -i '/^\s*$/d' /var/lib/lxc/deb7template/config

   #/ if [ "$DEBVERSION" = "7" ]; then
   #/    sed -i '/lxc.autodev/d' /var/lib/lxc/deb7template/config
   #/    sed -i '/lxc.kmsg/d' /var/lib/lxc/deb7template/config
   #/ fi

   echo "" # dummy
      "$DIR"/hooks/hook_deb7.sh
   echo "" # dummy
fi
checkhard lxc: deb7template

CHECKMANAGED1STATUS=$(screen -list | grep "managed" | awk '{print $1}')

if [ "$DEBVERSION" = "7" ]; then
   CHECKMANAGED1=$(lxc-ls --active | grep -c "managed")
   #/ CHECKMANAGED1=$(lxc-list | sed -e '/FROZEN/,+99d' | grep -c "managed") # lxc 0.8
   if [ "$CHECKMANAGED1" = "1" ]; then
      echo "... LXC Container (screen session: $CHECKMANAGED1STATUS): always running ..."
   else
      echo "... LXC Container (screen session): managed starting ..."
      #/screen -d -m -S managed -- lxc-start -n managed
### fix //
      if [ "$DEBIAN" = "ubuntu" ]
      then
         screen -d -m -S managed -- lxc-start -n managed -F
      else
         screen -d -m -S managed -- lxc-start -n managed
      fi
### // fix
      sleep 1
      screen -list | grep "managed"
      if [ "$GETENVIRONMENT" = "bridge" ]; then
         : # dummy
         echo "" # dummy
         (sleep 30) & spinner $!
         : # dummy
      fi
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         : # dummy
         echo "" # dummy
         (sleep 15) & spinner $!
         echo "" # dummy
         : # dummy
      fi
   fi
else
   #/if [ "$DEBVERSION" = "8" ]; then
   #/if [ "$DEBTESTVERSION" = "1" ]; then
   CHECKMANAGED2=$(lxc-ls --active | grep -c "managed")
   if [ "$CHECKMANAGED2" = "1" ]; then
      echo "... LXC Container (screen session: $CHECKMANAGED1STATUS): always running ..."
   else
      echo "... LXC Container (screen session): managed starting ..."
      #/screen -d -m -S managed -- lxc-start -n managed
### fix //
      if [ "$DEBIAN" = "ubuntu" ]
      then
         screen -d -m -S managed -- lxc-start -n managed -F
      else
         screen -d -m -S managed -- lxc-start -n managed
      fi
### // fix
      sleep 1
      screen -list | grep "managed"
      if [ "$GETENVIRONMENT" = "bridge" ]; then
         : # dummy
         echo "" # dummy
         (sleep 30) & spinner $!
         : # dummy
      fi
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         : # dummy
         echo "" # dummy
         (sleep 15) & spinner $!
         echo "" # dummy
         : # dummy
      fi
   fi
fi
checkhard lxc: managed bootstrap - stage 3

CHECKUPDATELIST1=$(grep "jessie" /var/lib/lxc/managed/rootfs/etc/apt/sources.list | head -n 1 | grep -c "jessie")
if [ "$CHECKUPDATELIST1" = "1" ]; then
   : # dummy
else
   /bin/cat << CHECKUPDATELIST1IN > /var/lib/lxc/managed/rootfs/etc/apt/sources.list
### ### ### PLITC ### ### ###
deb http://ftp.de.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free

deb http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ jessie-updates main contrib non-free

deb http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
deb-src http://ftp.de.debian.org/debian-security/ jessie/updates main contrib non-free
### ### ### PLITC ### ### ###
# EOF
CHECKUPDATELIST1IN
   lxc-attach -n managed -- apt-get clean
   lxc-attach -n managed -- apt-get update
   if [ "$?" != "0" ]; then
      rm -rf /var/lib/lxc/managed/rootfs/etc/apt/sources.list
      echo "[ERROR] can't fetch update list"
      exit 1
   fi
fi
checkhard lxc: managed upgrade - stage 1

DEBVERSIONMANAGED=$(grep "VERSION_ID" /var/lib/lxc/managed/rootfs/etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
if [ "$DEBVERSIONMANAGED" = "8" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y upgrade
   if [ "$?" != "0" ]; then
      echo "[ERROR] can't upgrade the LXC Container"
      echo '... try manually "lxc-attach -n managed -- apt-get -y upgrade"'
      if [ "$?" != "0" ]; then
         echo "[ERROR] can't upgrade"
         rm -rf /var/lib/lxc/managed/rootfs/etc/apt/sources.list
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
         exit 1
      fi
   fi
   lxc-attach -n managed -- apt-get -y dist-upgrade
   if [ "$?" != "0" ]; then
      echo "[ERROR] can't dist-upgrade the LXC Container"
      echo '... try manually "lxc-attach -n managed -- apt-get -y dist-upgrade"'
      if [ "$?" != "0" ]; then
         echo "[ERROR] can't dist-upgrade"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
         exit 1
      fi
   fi
   lxc-attach -n managed -- apt-get -y autoremove
   if [ "$?" != "0" ]; then
      echo '... try manually "lxc-attach -n managed -- apt-get -y autoremove"'
      echo "[ERROR] can't autoremove the LXC Container"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
      exit 1
   fi
   lxc-attach -n managed -- apt-get -y install --reinstall systemd-sysv
   if [ "$?" != "0" ]; then
      echo '... try manually "lxc-attach -n managed -- apt-get -y install --reinstall systemd-sysv"'
      echo "[ERROR] can't reinstall systemd-sysv the LXC Container"
         : # dummy
         read -p "Do you wish to remove this corrupt LXC Container: managed ? (y/n) " LXCMANAGEDREMOVE
         if [ "$LXCMANAGEDREMOVE" = "y" ]; then
            lxc-stop -n managed -k
            lxc-destroy -n managed
            lxc-destroy -n deb7template
         fi
      exit 1
   fi
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd.service
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd-control.socket
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/systemd-udevd-kernel.socket
   lxc-attach -n managed -- ln -s /dev/null /etc/systemd/system/proc-sys-fs-binfmt_misc.automount

   lxc-stop -n managed

   CHECKTEMPLATEDEB8=$(lxc-ls | grep -c "deb8template")
   if [ "$CHECKTEMPLATEDEB8" = "1" ]; then
      : # dummy
   else
      echo "" # dummy
      if [ "$DEBVERSION" = "7" ]; then
         (lxc-clone -o managed -n deb8template) & spinner $!
      else
         (lxc-clone -M -B dir -o managed -n deb8template) & spinner $!
      fi
      sed -i '/lxc.network.ipv4/d' /var/lib/lxc/deb8template/config
      sed -i '/lxc.network.ipv6/d' /var/lib/lxc/deb8template/config
      sed -i '0,/lxc.network.type = veth/s/lxc.network.type = veth//' /var/lib/lxc/deb8template/config
      sed -i '0,/lxc.network.flags = up/s/lxc.network.flags = up//' /var/lib/lxc/deb8template/config
      sed -i '0,/lxc.network.link = vswitch0/s/lxc.network.link = vswitch0//' /var/lib/lxc/deb8template/config
      sed -i '0,/lxc.network.name = eth0/s/lxc.network.name = eth0//' /var/lib/lxc/deb8template/config
      sed -i '0,/lxc.network.veth.pair = managed/s/lxc.network.veth.pair = managed//' /var/lib/lxc/deb8template/config
      #/ sed -i '0,/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa/s/lxc.network.hwaddr = aa:bb:c0:0c:bb:aa//' /var/lib/lxc/deb8template/config
      sed -i '/lxc.network.hwaddr/d' /var/lib/lxc/deb8template/config
      sed -i 's/managed1/deb8temp/g' /var/lib/lxc/deb8template/config
      sed -i '/^\s*$/d' /var/lib/lxc/deb8template/config

      #/ if [ "$DEBVERSION" = "8" ]; then
      #/    sed -i '/lxc.autodev/d' /var/lib/lxc/deb8template/config
      #/    sed -i '/lxc.kmsg/d' /var/lib/lxc/deb8template/config
      #/ fi

      echo "" # dummy
         "$DIR"/hooks/hook_deb8.sh
      echo "" # dummy
   fi
   echo "... LXC Container (screen session): managed restarting ..."
   #/screen -d -m -S managed -- lxc-start -n managed
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      screen -d -m -S managed -- lxc-start -n managed -F
   else
      screen -d -m -S managed -- lxc-start -n managed
   fi
### // fix
   sleep 1
   screen -list | grep "managed"
   echo "" # dummy
fi
checkhard lxc: managed upgrade - stage 2

CHECKMANAGEDIPTABLES1=$(lxc-attach -n managed -- dpkg -l | grep -c "iptables")
if [ "$CHECKMANAGEDIPTABLES1" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install iptables
fi
checkhard lxc: managed look over iptables

SYSCTLMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/sysctl.conf | awk '{print $4}' | head -n 1)
if [ X"$SYSCTLMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << SYSCTLFILEMANAGED > /var/lib/lxc/managed/rootfs/etc/sysctl.conf
### ### ### lxc-to-go // ### ### ###
#
net.ipv4.conf.eth0.forwarding=1
net.ipv4.conf.eth1.forwarding=1
net.ipv6.conf.eth0.forwarding=1
net.ipv6.conf.eth1.forwarding=1
net.ipv6.conf.all.forwarding=1
#
### ### ### // lxc-to-go ### ### ###
# EOF
SYSCTLFILEMANAGED
fi
checkhard lxc: managed sysctl

lxc-attach -n managed -- sysctl -w net.ipv4.conf.eth0.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv4.conf.eth1.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.eth0.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.eth1.forwarding=1 >/dev/null 2>&1
lxc-attach -n managed -- sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1

RCLOCALMANAGED=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/rc.local | awk '{print $4}' | head -n 1)
if [ X"$RCLOCALMANAGED" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << RCLOCALFILEMANAGED > /var/lib/lxc/managed/rootfs/etc/rc.local
#!/bin/sh -e
### ### ### lxc-to-go // ### ### ###
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

##/ echo "stage0"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

##/ echo "stage0"
sysctl net.ipv4.conf.default.forwarding=1 # LXC
sysctl net.ipv4.conf.eth0.forwarding=1    # LXC
sysctl net.ipv4.conf.eth1.forwarding=1    # LXC
sysctl net.ipv6.conf.eth0.forwarding=1    # LXC
sysctl net.ipv6.conf.eth1.forwarding=1    # LXC
sysctl net.ipv6.conf.all.forwarding=1     # LXC

##/ echo "stage1"
##/ ipv4 nat
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE    # LXC
##/ ipv6 nat
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE   # LXC
#/
# lxc1
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10001 -j DNAT --to-destination 192.168.254.101:10001
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10001 -j DNAT --to-destination 192.168.254.101:10001
# lxc2
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10002 -j DNAT --to-destination 192.168.254.102:10002
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10002 -j DNAT --to-destination 192.168.254.102:10002
# lxc3
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10003 -j DNAT --to-destination 192.168.254.103:10003
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10003 -j DNAT --to-destination 192.168.254.103:10003
# lxc4
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10004 -j DNAT --to-destination 192.168.254.104:10004
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10004 -j DNAT --to-destination 192.168.254.104:10004
# lxc5
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10005 -j DNAT --to-destination 192.168.254.105:10005
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10005 -j DNAT --to-destination 192.168.254.105:10005
# lxc6
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10006 -j DNAT --to-destination 192.168.254.106:10006
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10006 -j DNAT --to-destination 192.168.254.106:10006
# lxc7
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10007 -j DNAT --to-destination 192.168.254.107:10007
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10007 -j DNAT --to-destination 192.168.254.107:10007
# lxc8
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10008 -j DNAT --to-destination 192.168.254.108:10008
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10008 -j DNAT --to-destination 192.168.254.108:10008
# lxc9
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10009 -j DNAT --to-destination 192.168.254.109:10009
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10009 -j DNAT --to-destination 192.168.254.109:10009
# lxc10
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10010 -j DNAT --to-destination 192.168.254.110:10010
### # EXAMPLE #/ iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10010 -j DNAT --to-destination 192.168.254.110:10010
#/

##/ echo "stage2"
# ip -6 rule add from 2001::/64 table 100
# ip r a 2000::/3 dev eth0 via fe80:: table 100

##/ echo "stage3"
### IPredator // ###
# route add -net 46.246.38.0 netmask 255.255.255.0 gw 192.168.254.254
#
# mkdir -p /dev/net
# mknod /dev/net/tun c 10 200
# chmod 666 /dev/net/tun
#
# systemctl restart openvpn
### // IPredator ###

exit 0
#
### ### ### // lxc-to-go ### ### ###
# EOF
RCLOCALFILEMANAGED
fi
checkhard lxc: managed rc.local

CHECKMANAGEDNET=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/network/interfaces | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDNET" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDNETFILE > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
iface eth0 inet6 auto

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDNETFILE

   lxc-stop -n managed

   echo "" # dummy
   echo "... LXC Container (screen session): managed restarting ..."
   #/screen -d -m -S managed -- lxc-start -n managed
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      screen -d -m -S managed -- lxc-start -n managed -F
   else
      screen -d -m -S managed -- lxc-start -n managed
   fi
### // fix
   sleep 1
   screen -list | grep "managed"
   echo "" # dummy
fi
checkhard lxc: managed network settings

##/ less for systemd
CHECKMANAGEDLESS=$(lxc-attach -n managed -- dpkg -l | grep -c "less")
if [ "$CHECKMANAGEDLESS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install less
fi
checkhard lxc: managed look over less

##/ DHCP-Service

CHECKMANAGEDDHCP=$(lxc-attach -n managed -- dpkg -l | grep -c "isc-dhcp-server")
if [ "$CHECKMANAGEDDHCP" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install isc-dhcp-server
fi
checkhard lxc: managed look over isc-dhcp-server

CHECKMANAGEDDHCPCONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/dhcp/dhcpd.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDDHCPCONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDDHCPCONFIGFILE > /var/lib/lxc/managed/rootfs/etc/dhcp/dhcpd.conf
### ### ### lxc-to-go // ### ### ###
#
# /etc/dhcpd.conf for primary DHCP server
#

#/ option local-proxy-config code 252 = text;
#/ option root-path "iscsi:freenas.domain.tld:6:3260:0:iqn.2015-01.tld.domain:iscsiboot";

authoritative;                                             # server is authoritative
option domain-name "privat.local";                         # the domain name issued
option domain-search "privat.local";                       # dns search
option domain-name-servers 192.168.254.254;                    # name servers issued

#/ option netbios-name-servers 192.168.254.254;                # netbios servers
#/ allow booting;                                          # allow for booting over the network
#/ allow bootp;                                            # allow for booting
#/ next-server 192.168.254.254;                                # TFTP server for booting
#/ filename "pxelinux.0";                                  # kernel for network booting
#/ ddns-update-style interim;                              # setup dynamic DNS updates
#/ ddns-updates on;
#/ ddns-domainname "extern.global.";                       # domain name for DDNS updates
#/ do-forward-updates on;
#/ ddns-rev-domainname "in-addr.arpa.";

default-lease-time 86400;
max-lease-time 604800;

#/ key dhcp.domain.tld {
#/     algorithm hmac-md5;
#/     secret "... SECRETHASH ...";
#/ }
#/ zone extern.global.
#/ {
#/     primary 0.0.0.0;
#/     key dhcp.domain.tld;
#/ }
#/ zone 1.168.192.in-addr.arpa.
#/ {
#/     primary 0.0.0.0;
#/     key dhcp.domain.tld;
#/ }

#/ failover peer "dhcp-failover" {                         # fail over configuration
#/          primary;                                       # this is the secondary
#/          address 192.168.254.254;                           # our ip address
#/          port 647;
#/          peer address 192.168.254.253;                      # primary's ip address
#/          peer port 647;
#/          max-response-delay 60;
#/          max-unacked-updates 10;
#/          mclt 3600;
#/          split 128;                                     # for primary only
#/          load balance max seconds 3;
#/ }

subnet 192.168.254.0 netmask 255.255.255.0                   # zone to issue addresses from
{
        pool {
                #/ failover peer "dhcp-failover";          # pool for dhcp, bootp leases with failover
                #/ option local-proxy-config "http://192.168.254.254/proxy.pac";

                option routers 192.168.254.254;
                range 192.168.254.101 192.168.254.200;

### fixed-address // ###
#
#/  host managed {
#/    hardware ethernet aa:bb:c0:0c:bb:aa;
#/    fixed-address managed.privat.local;
#/  }
#
### // fixed-address ###

           }
#/         pool {                                          # accomodate our bootp clients here no replication and failover
#/                option routers 10.0.0.1;
#/                range 10.0.0.100 10.0.0.200;
#/         }

        allow unknown-clients;
        ignore client-updates;
}

log-facility local7;

#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDDHCPCONFIGFILE
   lxc-attach -n managed -- systemctl restart isc-dhcp-server
fi
checkhard lxc: managed isc-dhcp-server configcheck

##/ DNS-Service (unbound)

CHECKMANAGEDDNS=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "unbound")
if [ "$CHECKMANAGEDDNS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install unbound
fi
checkhard lxc: managed look over unbound

CHECKMANAGEDDNSCONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/unbound/unbound.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDDNSCONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDDNSCONFIGFILE > /var/lib/lxc/managed/rootfs/etc/unbound/unbound.conf
### ### ### lxc-to-go // ### ### ###
#
server:
### < --- server // --- > ###
verbosity: 2
 
# interface: 192.168.254.254
# interface: 192.168.254.254@5003
# interface: 2001::1

interface: 127.0.0.1
interface: ::1
interface: 192.168.254.254
interface: fd00:aaaa:254::254

# outgoing-interface: 192.168.254.254
# outgoing-interface: 192.168.254.254@5003
# outgoing-interface: 2001::1
 
access-control: 0.0.0.0/0 allow
access-control: ::/0 allow
 
outgoing-port-permit: 1025-65535
outgoing-port-avoid: 0-1024
 
harden-large-queries: "yes"
harden-short-bufsize: "yes"
 
statistics-interval: 60
 
#/ logfile: "/usr/local/etc/unbound/unbound.log"
 
#/ root-hints: "/usr/local/etc/unbound/named.cache"
#/ auto-trust-anchor-file: "/usr/local/etc/unbound/root.key"
 
port: 53
 
do-ip4: yes
do-ip6: yes
do-udp: yes
do-tcp: yes
 
hide-identity: yes
hide-version: yes
harden-glue: yes
harden-dnssec-stripped: yes
 
use-caps-for-id: yes
 
cache-min-ttl: 3600
cache-max-ttl: 86400
 
prefetch: yes
num-threads: 2
 
max-udp-size: 512
edns-buffer-size: 512
 
# with libevent2
outgoing-range: 8192
num-queries-per-thread: 4096
 
msg-cache-slabs: 8
rrset-cache-slabs: 8
infra-cache-slabs: 8
key-cache-slabs: 8
 
rrset-cache-size: 256m
msg-cache-size: 128m
 
so-rcvbuf: 1m
 
unwanted-reply-threshold: 10000
val-clean-additional: yes
### < --- // server --- > ###
python:
 
remote-control:
 
# forward-zone:
# name: "."
# forward-addr: 213.73.91.35  # dnscache.berlin.ccc.de
# forward-addr: 74.82.42.42   # Hurricane Electric
# forward-addr: 4.2.2.4       # Level3 Verizon
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDDNSCONFIGFILE
   lxc-attach -n managed -- systemctl restart unbound
fi
checkhard lxc: managed unbound configcheck

##/ RA-Service

CHECKMANAGEDIPV6D=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "radvd")
if [ "$CHECKMANAGEDIPV6D" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install radvd
fi
checkhard lxc: managed look over radvd

touch /var/lib/lxc/managed/rootfs/etc/radvd.conf
CHECKMANAGEDIPV6CONFIG=$(grep "lxc-to-go" /var/lib/lxc/managed/rootfs/etc/radvd.conf | awk '{print $4}' | head -n 1)
if [ X"$CHECKMANAGEDIPV6CONFIG" = X"lxc-to-go" ]; then
   : # dummy
else
/bin/cat << CHECKMANAGEDIPV6CONFIGFILE > /var/lib/lxc/managed/rootfs/etc/radvd.conf
### ### ### lxc-to-go // ### ### ###
#
interface eth1
{ 
        AdvSendAdvert on;
        MinRtrAdvInterval 3; 
        MaxRtrAdvInterval 10;
        prefix fd00:aaaa:254::/64
	{ 
                AdvOnLink on; 
                AdvAutonomous on; 
                AdvRouterAddr on; 
        };
	AdvDefaultPreference high;
	RDNSS fd00:aaaa:254::254 { };
};
#
### ### ### // lxc-to-go ### ### ###
# EOF
CHECKMANAGEDIPV6CONFIGFILE
   lxc-attach -n managed -- service radvd restart
   ### bootstrap finished file // ###
   touch /etc/lxc-to-go/INSTALLED
   ### // bootstrap finished file ###
   #
   # set iptables rules // ###
   lxc-attach -n managed -- /etc/rc.local >/dev/null 2>&1
   # set iptables rules // ###
fi
checkhard lxc: managed radvd configcheck

### network debug tools // ###
CHECKMANAGEDIPUTILS=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "iputils-ping")
if [ "$CHECKMANAGEDIPUTILS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install iputils-ping
fi
checkhard lxc: managed look over iputils-ping

CHECKMANAGEDTRACEROUTE=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "traceroute")
if [ "$CHECKMANAGEDTRACEROUTE" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install traceroute
fi
checkhard lxc: managed look over traceroute

CHECKMANAGEDDNSUTILS=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "dnsutils")
if [ "$CHECKMANAGEDDNSUTILS" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install dnsutils
fi
checkhard lxc: managed look over dnsutils

CHECKMANAGEDMTRTINY=$(lxc-attach -n managed -- dpkg -l | awk '{print $2}' | grep -xc "mtr-tiny")
if [ "$CHECKMANAGEDMTRTINY" = "1" ]; then
   : # dummy
else
   lxc-attach -n managed -- apt-get -y install mtr-tiny
fi
checkhard lxc: managed look over mtr-tiny
### // network debug tools ###

### NEW IP - Bridge Environment // ###
if [ "$GETENVIRONMENT" = "bridge" ]; then
   #/ ipv4
   #/ killall dhclient
   if [ -e "$UDEVNET" ]; then
      #/ dhclient "$GETBRIDGEPORT0" >/dev/null 2>&1
      #/ route del default dev "$GETBRIDGEPORT0" >/dev/null 2>&1
      if [ "$DEBVERSION" = "7" ]; then
         pgrep -f "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBVERSION" = "8" ]; then
         ps -ax | grep "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBTESTVERSION" = "1" ]; then
         ps -ax | grep "[dhclient] '"$GETBRIDGEPORT0"'" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      ip addr flush "$GETBRIDGEPORT0"
      echo "" # dummy
      echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT $GETBRIDGEPORT0"
   else
      #/ dhclient "$GETINTERFACE" >/dev/null 2>&1
      #/ route del default dev "$GETINTERFACE" >/dev/null 2>&1
      if [ "$DEBVERSION" = "7" ]; then
         pgrep -f "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         pgrep -f "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBVERSION" = "8" ]; then
         ps -ax | grep "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      if [ "$DEBTESTVERSION" = "1" ]; then
         ps -ax | grep "[dhclient] $GETINTERFACE" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
         ps -ax | grep "[dhclient] vswitch0" | awk '{print $1}' | xargs -L1 -I % kill -9 % > /dev/null 2>&1
      fi
      ip addr flush "$GETINTERFACE"
      echo "" # dummy
      echo "WARNING: if you want to change the default gateway on the HOST please use 'via vswitch0' and NOT '"$GETINTERFACE"'"
   fi
   dhclient vswitch0 >/dev/null 2>&1
### fix //
   CHECKGETIPV4DEFAULTGATEWAY3=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
   if [ "$CHECKGETIPV4DEFAULTGATEWAY3" = "2" ]; then
      route del default
   fi
### // fix
   #/ ipv6
   if [ -e "$UDEVNET" ]; then
      #/ ifconfig "$GETBRIDGEPORT0" | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I % ifconfig vswitch0 inet6 add % >/dev/null 2>&1
      ip -6 route del ::/0 >/dev/null 2>&1
      echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
   else
      #/ ifconfig "$GETINTERFACE" | grep "inet6" | egrep -v "fe80" | awk '{print $2}' | xargs -L1 -I % ifconfig vswitch0 inet6 add % >/dev/null 2>&1
      ip -6 route del ::/0 >/dev/null 2>&1
      echo "2" > /proc/sys/net/ipv6/conf/vswitch0/accept_ra
   fi
   #/ container
   #/ lxc-attach -n managed -- pkill dhclient
   lxc-attach -n managed -- killall dhclient >/dev/null 2>&1
   lxc-attach -n managed -- ip addr flush eth0 >/dev/null 2>&1
   lxc-attach -n managed -- dhclient eth0 >/dev/null 2>&1
   lxc-attach -n managed -- ip -6 route del ::/0 >/dev/null 2>&1
   lxc-attach -n managed -- echo "2" > /proc/sys/net/ipv6/conf/eth0/accept_ra
   ### rc.local reload // ###
   lxc-attach -n managed -- /etc/rc.local >/dev/null 2>&1
   ### // rc.local reload ###
fi
checkhard prepare bridge zones - stage 4
### // NEW IP - Bridge Environment ###

### NEW IP - Proxy Environment // ###
if [ "$GETENVIRONMENT" = "proxy" ]; then
   #/ ipv4
   netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | xargs -L1 -I % echo "IPV4DEFAULTGATEWAY=%" > /tmp/lxc-to-go_IPV4GATEWAY.log
   chmod 0700 /tmp/lxc-to-go_IPV4GATEWAY.log
   if [ -e "$UDEVNET" ]; then
      GETIPV4UDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNETUDEV=$(ifconfig "$GETBRIDGEPORT0" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep "255.255.255" | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ip addr flush vswitch0
      ip link set dev vswitch0 up > /dev/null 2>&1
      #/ifconfig vswitch0 inet "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV"
      ip addr add "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV" dev vswitch0
### fix //
      if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
      then
         ip addr del "$GETIPV4UDEV"/"$GETIPV4SUBNETUDEV" dev vswitch0
      fi
### // fix
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         ip addr add 192.168.253.253/24 dev vswitch0
      fi
### fix //
      CHECKGETIPV4DEFAULTGATEWAY1=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
      if [ "$CHECKGETIPV4DEFAULTGATEWAY1" = "2" ]; then
         #/route del default
         : # dummy
      fi
### // fix
   else
      GETIPV4=$(ifconfig "$GETINTERFACE" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
      GETIPV4SUBNET=$(ifconfig "$GETINTERFACE" | grep "inet " | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep "255.255.255" | sed 's/255.255.255.0/24/' | sed 's/255.255.255.224/27/')
      ip addr flush vswitch0
      ip link set dev vswitch0 up > /dev/null 2>&1
      #/ifconfig vswitch0 inet "$GETIPV4"/"$GETIPV4SUBNET"
      ip addr add "$GETIPV4"/"$GETIPV4SUBNET" dev vswitch0
### fix //
      if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
      then
         ip addr del "$GETIPV4"/"$GETIPV4SUBNET" dev vswitch0
      fi
### // fix
      if [ "$GETENVIRONMENT" = "proxy" ]; then
         ip addr add 192.168.253.253/24 dev vswitch0
      fi
### fix //
      CHECKGETIPV4DEFAULTGATEWAY2=$(netstat -rn4 | grep "^0.0.0.0" | awk '{print $2}' | grep -c "")
      if [ "$CHECKGETIPV4DEFAULTGATEWAY2" = "2" ]; then
         #/route del default
         : # dummy
      fi
### // fix
   fi
   ### ### ###
   #/ ipv6
   if [ "$GETENVIRONMENT" = "proxy" ]; then
      netstat -rn6 | grep "^::/0" | egrep -v "lo" | awk '{print $2}' | xargs -L1 -I % echo "IPV6DEFAULTGATEWAY=%" > /tmp/lxc-to-go_IPV6GATEWAY.log
      chmod 0700 /tmp/lxc-to-go_IPV6GATEWAY.log
      if [ -e "$UDEVNET" ]; then
         GETIPV6UDEV=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/\/.*$//')
         GETIPV6SUBNETUDEV=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/.*\///')
         ip -6 addr add "$GETIPV6UDEV"/"$GETIPV6SUBNETUDEV" dev vswitch0 >/dev/null 2>&1
### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            ip -6 addr del "$GETIPV6UDEV"/"$GETIPV6SUBNETUDEV" dev vswitch0 >/dev/null 2>&1
         fi
### // fix
         if [ "$GETENVIRONMENT" = "proxy" ]; then
            ip -6 addr add fd00:aaaa:253::253/64 dev vswitch0 >/dev/null 2>&1
         fi
### fix //
         GETIPV6UDEVLL2=$(ip -6 addr show "$GETBRIDGEPORT0" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | grep "fe80" | head -n 1 | sed 's/\/.*$//')
         ip -6 addr add "$GETIPV6UDEVLL2"/64 dev vswitch0 >/dev/null 2>&1
   ### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            #// need link local!
            #/ip -6 addr del "$GETIPV6UDEVLL2"/64 dev vswitch0 >/dev/null 2>&1
            : # dummy
         fi
   ### // fix
### // fix
      else
         GETIPV6=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/\/.*$//')
         GETIPV6SUBNET=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | egrep -v "fe80" | head -n 1 | sed 's/.*\///')
         ip -6 addr add "$GETIPV6"/"$GETIPV6SUBNET" dev vswitch0 >/dev/null 2>&1
### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            ip -6 addr del "$GETIPV6"/"$GETIPV6SUBNET" dev vswitch0 >/dev/null 2>&1
         fi
### // fix
         if [ "$GETENVIRONMENT" = "proxy" ]; then
            ip -6 addr add fd00:aaaa:253::253/64 dev vswitch0 >/dev/null 2>&1
         fi
### fix //
         GETIPV6LL2=$(ip -6 addr show "$GETINTERFACE" | grep "inet6 " | awk '{print $2}' | grep -Eo '[a-z0-9\.:/]*' | grep "/" | grep "fe80" | head -n 1 | sed 's/\/.*$//')
         ip -6 addr add "$GETIPV6LL2"/64 dev vswitch0 >/dev/null 2>&1
   ### fix //
         if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" -o "$DEBIAN" = "devuan" ]
         then
            #// need link local!
            #/ip -6 addr del "$GETIPV6LL2"/64 dev vswitch0 >/dev/null 2>&1
            : # dummy
         fi
   ### // fix
### // fix
      fi
      ### ### ###
      #/ container
      ### rc.local reload // ###
      CHECKBOOTSTRAPINSTALL02="/etc/lxc-to-go/INSTALLED"
      if [ -e "$CHECKBOOTSTRAPINSTALL02" ]; then
         : # dummy
      else
         lxc-attach -n managed -- /etc/rc.local >/dev/null 2>&1 # break forwarding rules inside managed lxc
      fi
      ### // rc.local reload ###
   fi
fi
checkhard prepare bridge zones - stage 5
### // NEW IP - Proxy Environment ###

### RP_FILTER // ###
sysctl -w net.ipv4.conf.all.rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf.default.rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf."$GETINTERFACE".rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf.managed.rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf.managed1.rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf.vswitch0.rp_filter=1 >/dev/null 2>&1
sysctl -w net.ipv4.conf.vswitch1.rp_filter=1 >/dev/null 2>&1
if [ -e "$UDEVNET" ]; then
   sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".rp_filter=1 >/dev/null 2>&1
fi
checkhard configure rp_filter sysctl
### // RP_FILTER ###

### SYMBOLIC LINKS // ###
CHECKSYMLINK1="/usr/sbin/lxc-to-go"
if [ -e "$CHECKSYMLINK1" ]; then
   : # dummy
else
   ln -sf "$ADIR"/lxc-to-go.sh /usr/sbin/lxc-to-go
   ln -sf "$ADIR"/lxc-to-go-provisioning.sh /usr/sbin/lxc-to-go-provisioning
   ln -sf "$ADIR"/lxc-to-go-template.sh /usr/sbin/lxc-to-go-template
fi
checkhard configure lxc-to-go symlinks - stage 1
#
#/CHECKSYMLINK2="/usr/sbin/lxc-to-go-ci"
#/if [ -e "$CHECKSYMLINK2" ]; then
CHECKSYMLINK2=$(basename $0)
if [ "$CHECKSYMLINK2" = "lxc-to-go-ci.sh" ]
then
   #/ln -sf "$ADIR"/lxc-to-go-ci.sh /usr/sbin/lxc-to-go-ci
   #/ln -sf "$ADIR"/lxc-to-go-ci-provisioning.sh /usr/sbin/lxc-to-go-ci-provisioning
   : # dummy
else
   : # dummy
fi
checkhard configure lxc-to-go symlinks - stage 2
### // SYMBOLIC LINKS ###

CHECKETCHOSTS0=$(grep -c "lxc-to-go" /etc/hosts)
if [ "$CHECKETCHOSTS0" = "0" ]
then
   echo "192.168.253.254   lxc-to-go" >> /etc/hosts
fi
checkhard configure lxc-to-go etc/hosts entry

### LXC-inside-LXC // ###
## echo "" # dummy
## echo "... prepare LXC-inside-LXC (if necessary) ..."
## #/lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then brctl addbr lxc-in-lxc >/dev/null 2>&1; brctl addif lxc-in-lxc eth1 >/dev/null 2>&1; ifconfig lxc-in-lxc up; else :; fi'
## lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then brctl addbr lxc-in-lxc >/dev/null 2>&1; ip link set dev lxc-in-lxc up; else :; fi'
## lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then ip addr add 192.168.252.254/24 dev lxc-in-lxc >/dev/null 2>&1; else :; fi'
## lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then sysctl -w net.ipv4.conf.lxc-in-lxc.forwarding=1 >/dev/null 2>&1; else :; fi'
## lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then sysctl -w net.ipv6.conf.lxc-in-lxc.forwarding=1 >/dev/null 2>&1; else :; fi'
### // LXC-inside-LXC ###

### restricting container view of dmesg // ###
echo 1 > /proc/sys/kernel/dmesg_restrict
### // restricting container view of dmesg ###

### LXC X11 Video & Audio // ###
CHECKPULSEAUDIO=$(/usr/bin/dpkg -l | grep -swc "ii  pulseaudio ")
if [ "$CHECKPULSEAUDIO" = "1" ]
then
   # quick & dirty
   GETLASTUSER=$(/usr/bin/last | egrep -v "root" | head -n 1 | awk '{print $1}')
   if [ -z "$GETLASTUSER" ]
   then
      : # dummy
   else
      GETX11STATE=$(/bin/ps -ax | pgrep -c "Xorg")
      if [ "$GETX11STATE" = "0" ]
      then
         : # dummy
      else
         GETPULSEAUDIOSTATE=$(/bin/ss -l | grep -sc "4713")
         if [ "$GETPULSEAUDIOSTATE" = "0" ]
         then
            SUDO=$(/usr/bin/which sudo)
            if [ -z "$SUDO" ]
            then
               echo "<--- --- --->"
               echo "need sudo"
               echo "<--- --- --->"
               apt-get update
               apt-get -y install sudo
               echo "<--- --- --->"
            fi
            PAPREFS=$(/usr/bin/which paprefs)
            if [ -z "$PAPREFS" ]
            then
               echo "<--- --- --->"
               echo "need paprefs & pulseaudio-module-zeroconf"
               echo "<--- --- --->"
               apt-get update
               apt-get -y install paprefs pulseaudio-module-zeroconf
               echo "<--- --- --->"
            fi
            /usr/bin/sudo /bin/su -s /bin/sh -c ' pactl load-module module-native-protocol-tcp auth-ip-acl=192.168.253.0/24 auth-anonymous=1 ' "$GETLASTUSER"
            printf "\033[1;33m WARNING: PulseAudio listen on (vswitch0) Port 4713 now! \033[0m\n"
         else
            : # dummy
         fi
      fi
   fi
fi
checkhard optional: prepare lxc x11 video / audio environment
### // LXC X11 Video & Audio ###

### LXC: managed Service State // ###
echo "" # dummy
lxc-attach -n managed -- systemctl status isc-dhcp-server
echo "" # dummy
### fix //
CHECKLXCMANAGEDDHCP=$(lxc-attach -n managed -- /bin/sh -c ' systemctl status isc-dhcp-server | egrep -c "inactive (dead)" ')
if [ "$CHECKLXCMANAGEDDHCP" = "1" ]
then
   lxc-attach -n managed -- systemctl restart isc-dhcp-server
   sleep 2
   lxc-attach -n managed -- systemctl status isc-dhcp-server
   checksoft LXC Managed: isc-dhcp-server restart
   echo "" # dummy
fi
### // fix
lxc-attach -n managed -- systemctl status unbound
echo "" # dummy
### fix //
CHECKLXCMANAGEDUNBOUND=$(lxc-attach -n managed -- /bin/sh -c ' systemctl status unbound | egrep -c "Starting (null)|fatal error" ')
if [ "$CHECKLXCMANAGEDUNBOUND" = "1" ]
then
   lxc-attach -n managed -- systemctl restart unbound
   sleep 2
   lxc-attach -n managed -- systemctl status unbound
   checksoft LXC Managed: unbound restart
   echo "" # dummy
fi
### // fix
lxc-attach -n managed -- systemctl status radvd
echo "" # dummy
### // LXC: managed Service State ###

cleanup
checkhard clean up tmp files
### ### ### ### ### ### ### ### ###
echo "" # printf
printf "\033[1;32mlxc-to-go bootstrap finished.\033[0m\n"
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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'start')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###

### stage3 // ###
#
CHECKLXCINSTALL1=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL1" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKCONTAINER1=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKCONTAINER1" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 2

CHECKLXCSTARTMANAGED=$(lxc-ls --active | grep -c "managed")
if [ "$CHECKLXCSTARTMANAGED" = "1" ]; then
   : # dummy
else
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 3

CHECKLXCSTART1=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKLXCSTART1" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 4

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### ### ###
#/ echo "FOUND:"
#/ lxc-ls | egrep -v "managed|deb7template|deb8template" | tr '\n' ' '
#/echo "" # dummy

#/lxc-ls | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ echo ""; echo "---> starting: '"%"'";screen -d -m -S "%" -- lxc-start -n "%"; sleep 5; }' & spinner $!

### fix //
###if [ "$DEBIAN" = "ubuntu" ]
###then
###   lxc-ls | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ echo ""; echo "---> starting: '"%"'";screen -d -m -S "%" -- lxc-start -n "%" -F; sleep 5; }' & spinner $!
###else
###   lxc-ls | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ echo ""; echo "---> starting: '"%"'";screen -d -m -S "%" -- lxc-start -n "%"; sleep 5; }' & spinner $!
###fi
###checkhard lxc-to-go start
### // fix

lxcstartall

#/echo "" # dummy
echo "... LXC Container (screen sessions): ..."
lxc-ls | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ screen -list | grep "%"; }'
checksoft lxc-to-go screen sessions
### ### ###

lxcstartportforwarding

### CHECK FORWARDING RULES // ###
CHECKFORWARDINGRULES=$(cat /etc/lxc-to-go/portforwarding.conf | awk '{print $3}' | sed 's/,/ /g' | tr ' ' '\n' | awk 'array[$0]++' | grep -sc "")
if [ "$CHECKFORWARDINGRULES" = "0" ]; then
   : # dummy
else
   echo "" # dummy
   echo "[WARNING] some port forwarding rules are duplicated!"
   echo "" # dummy
   echo "[SOLUTION]:"
   echo "--1--> lxc-to-go stop"
   echo "--2--> check the /etc/lxc-to-go/portforwarding.conf file"
   echo "--3--> iptables -t nat -F"
   echo "--4--> lxc-attach -n managed -- iptables -t nat -F"
   echo "--5--> lxc-to-go bootstrap"
   echo "--6--> lxc-to-go start"
fi
checkhard lxc-to-go duplicated portforwarding rules
### // CHECK FORWARDING RULES ###

cleanup
checkhard clean up tmp files
### ### ###
echo "" # printf
printf "\033[1;32mlxc-to-go start finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'stop')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL2=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL2" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKCONTAINER2=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKCONTAINER2" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 2

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### ### ###
#/ echo "FOUND (active):"
#/ lxc-ls --active | egrep -v "managed|deb7template|deb8template" | tr '\n' ' '
#/echo "" # dummy

### FORWARDING // ###
#/echo "" # dummy
sleep 5
CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
if [ -e "$CHECKFORWARDINGFILE" ]; then
   # ipv4 //
   lxc-ls --active --fancy | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | awk '{print $1,$3}' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp
   #/ single port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | sed '/,/d' | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.s.tmp
   #/ multi port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "," | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp
   #
   ### set iptable rules // ###
   #/ single port support
   (
   while read -r line
   do
      set -- $line
      #
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      #
      CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
      #
      ### set iptable rules on HOST // ###
      if [ "$CHECKENVIRONMENT" = "proxy" ]; then
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
      fi
      ### // set iptable rules on HOST ###
      #
   done < "/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.s.tmp"
   )
   #/ multi port support
   STOPMULTIPORTSUPPORTFILE="/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp"
   if [ -z "$STOPMULTIPORTSUPPORTFILE" ]; then
      : # dummy
   else
       #/ dirty but functional (up to 5 ports)
       cat /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.dirty.tmp
       (
       while read -r line
       do
          set -- $line
          ###/ delete MPORTS /###
          #/ MPORT 1
          lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
          lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
          #/ MPORT 2
          if [ ! -z "$3" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
          fi
          #/ MPORT 3
          if [ ! -z "$4" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
          fi
          #/ MPORT 4
          if [ ! -z "$5" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
          fi
          #/ MPORT 5
          if [ ! -z "$6" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
          fi
          #/ MPORT 6
          if [ ! -z "$7" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
          fi
          #/ MPORT 7
          if [ ! -z "$8" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
          fi
          #/ MPORT 8
          if [ ! -z "$9" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
          fi
          #/ MPORT 9
          if [ ! -z "${10}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
          fi
          #/ MPORT 10
          if [ ! -z "${11}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
          fi
          #/ MPORT 11
          if [ ! -z "${12}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
          fi
          #/ MPORT 12
          if [ ! -z "${13}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
          fi
          #/ MPORT 13
          if [ ! -z "${14}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
          fi
          #/ MPORT 14
          if [ ! -z "${15}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
          fi
          #/ MPORT 15
          if [ ! -z "${16}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
          fi
          #/ MPORT 16
          if [ ! -z "${17}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
          fi
          #/ MPORT 17
          if [ ! -z "${18}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
          fi
          #/ MPORT 18
          if [ ! -z "${19}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
          fi
          #/ MPORT 19
          if [ ! -z "${20}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
          fi
          #/ MPORT 20
          if [ ! -z "${21}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
          fi
          #
          CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
          #
          ### set iptable rules on HOST // ###
          if [ "$CHECKENVIRONMENT" = "proxy" ]; then
             ###/ delete MPORTS /###
             #/ MPORT 1
             iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
             iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
             #/ MPORT 2
             if [ ! -z "$3" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
             fi
             #/ MPORT 3
             if [ ! -z "$4" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
             fi
             #/ MPORT 4
             if [ ! -z "$5" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
             fi
             #/ MPORT 5
             if [ ! -z "$6" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
             fi
             #/ MPORT 6
             if [ ! -z "$7" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
             fi
             #/ MPORT 7
             if [ ! -z "$8" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
             fi
             #/ MPORT 8
             if [ ! -z "$9" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
             fi
             #/ MPORT 9
             if [ ! -z "${10}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
             fi
             #/ MPORT 10
             if [ ! -z "${11}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
             fi
             #/ MPORT 11
             if [ ! -z "${12}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
             fi
             #/ MPORT 12
             if [ ! -z "${13}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
             fi
             #/ MPORT 13
             if [ ! -z "${14}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
             fi
             #/ MPORT 14
             if [ ! -z "${15}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
             fi
             #/ MPORT 15
             if [ ! -z "${16}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
             fi
             #/ MPORT 16
             if [ ! -z "${17}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
             fi
             #/ MPORT 17
             if [ ! -z "${18}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
             fi
             #/ MPORT 18
             if [ ! -z "${19}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
             fi
             #/ MPORT 19
             if [ ! -z "${20}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
             fi
             #/ MPORT 20
             if [ ! -z "${21}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
             fi
          fi
          ### // set iptable rules on HOST ###
          #
       done < "/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.dirty.tmp"
       )
   fi
   ### // set iptable rules ###
   # // ipv4
fi
checkhard lxc-to-go portforwarding
### // FORWARDING ###

#/lxc-ls --active | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ echo ""; echo "---> shutdown: '"%"'"; lxc-stop -n "%"; sleep 5; }' & spinner $!
#/checkhard lxc-to-go shutdown

lxcstopall

cleanup
checkhard clean up tmp files
### ### ###
echo "" # printf
printf "\033[1;32mlxc-to-go stop finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'shutdown')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL2=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL2" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

#/CHECKCONTAINER2=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
#/if [ "$CHECKCONTAINER2" = "0" ]; then
#/   echo "" # dummy
#/   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
#/   exit 1
#/fi

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### ### ###
#/ echo "FOUND (active):"
#/ lxc-ls --active | egrep -v "managed|deb7template|deb8template" | tr '\n' ' '
#/echo "" # dummy

### FORWARDING // ###
#/echo "" # dummy
sleep 5
CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
if [ -e "$CHECKFORWARDINGFILE" ]; then
   # ipv4 //
   lxc-ls --active --fancy | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | awk '{print $1,$3}' | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp
   #/ single port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | sed '/,/d' | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.s.tmp
   #/ multi port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.stop.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "," | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp
   #
   ### set iptable rules // ###
   #/ single port support
   (
   while read -r line
   do
      set -- $line
      #
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      #
      CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
      #
      ### set iptable rules on HOST // ###
      if [ "$CHECKENVIRONMENT" = "proxy" ]; then
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
      fi
      ### // set iptable rules on HOST ###
      #
   done < "/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.s.tmp"
   )
   #/ multi port support
   STOPMULTIPORTSUPPORTFILE="/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp"
   if [ -z "$STOPMULTIPORTSUPPORTFILE" ]; then
      : # dummy
   else
       #/ dirty but functional (up to 5 ports)
       cat /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.dirty.tmp
       (
       while read -r line
       do
          set -- $line
          ###/ delete MPORTS /###
          #/ MPORT 1
          lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
          lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
          #/ MPORT 2
          if [ ! -z "$3" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
          fi
          #/ MPORT 3
          if [ ! -z "$4" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
          fi
          #/ MPORT 4
          if [ ! -z "$5" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
          fi
          #/ MPORT 5
          if [ ! -z "$6" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
          fi
          #/ MPORT 6
          if [ ! -z "$7" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
          fi
          #/ MPORT 7
          if [ ! -z "$8" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
          fi
          #/ MPORT 8
          if [ ! -z "$9" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
          fi
          #/ MPORT 9
          if [ ! -z "${10}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
          fi
          #/ MPORT 10
          if [ ! -z "${11}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
          fi
          #/ MPORT 11
          if [ ! -z "${12}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
          fi
          #/ MPORT 12
          if [ ! -z "${13}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
          fi
          #/ MPORT 13
          if [ ! -z "${14}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
          fi
          #/ MPORT 14
          if [ ! -z "${15}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
          fi
          #/ MPORT 15
          if [ ! -z "${16}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
          fi
          #/ MPORT 16
          if [ ! -z "${17}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
          fi
          #/ MPORT 17
          if [ ! -z "${18}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
          fi
          #/ MPORT 18
          if [ ! -z "${19}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
          fi
          #/ MPORT 19
          if [ ! -z "${20}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
          fi
          #/ MPORT 20
          if [ ! -z "${21}" ]; then
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
             lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
          fi
          #
          CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
          #
          ### set iptable rules on HOST // ###
          if [ "$CHECKENVIRONMENT" = "proxy" ]; then
             ###/ delete MPORTS /###
             #/ MPORT 1
             iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
             iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
             #/ MPORT 2
             if [ ! -z "$3" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
             fi
             #/ MPORT 3
             if [ ! -z "$4" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
             fi
             #/ MPORT 4
             if [ ! -z "$5" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
             fi
             #/ MPORT 5
             if [ ! -z "$6" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
             fi
             #/ MPORT 6
             if [ ! -z "$7" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
             fi
             #/ MPORT 7
             if [ ! -z "$8" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
             fi
             #/ MPORT 8
             if [ ! -z "$9" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
             fi
             #/ MPORT 9
             if [ ! -z "${10}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
             fi
             #/ MPORT 10
             if [ ! -z "${11}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
             fi
             #/ MPORT 11
             if [ ! -z "${12}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
             fi
             #/ MPORT 12
             if [ ! -z "${13}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
             fi
             #/ MPORT 13
             if [ ! -z "${14}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
             fi
             #/ MPORT 14
             if [ ! -z "${15}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
             fi
             #/ MPORT 15
             if [ ! -z "${16}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
             fi
             #/ MPORT 16
             if [ ! -z "${17}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
             fi
             #/ MPORT 17
             if [ ! -z "${18}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
             fi
             #/ MPORT 18
             if [ ! -z "${19}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
             fi
             #/ MPORT 19
             if [ ! -z "${20}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
             fi
             #/ MPORT 20
             if [ ! -z "${21}" ]; then
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
                iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
             fi
          fi
          ### // set iptable rules on HOST ###
          #
       done < "/etc/lxc-to-go/tmp/lxc.ipv4.stop.list.m.dirty.tmp"
       )
   fi
   ### // set iptable rules ###
   # // ipv4
fi
checkhard lxc-to-go portforwarding
### // FORWARDING ###

#/lxc-ls --active | egrep -v "managed|deb7template|deb8template" | xargs -L1 -I % sh -c '{ echo ""; echo "---> shutdown: '"%"'"; lxc-stop -n "%"; sleep 5; }' & spinner $!
#/checkhard lxc-to-go stop
#/lxc-ls --active | grep "managed" | xargs -L1 -I % sh -c '{ echo ""; echo "---> shutdown: '"%"'"; lxc-stop -n "%"; sleep 5; }' & spinner $!
#/checkhard lxc-to-go shutdown

lxcstopall
lxcstopmanaged

ip link set dev vswitch1 down > /dev/null 2>&1
ip link set dev vswitch0 down > /dev/null 2>&1
ip link del vswitch0 > /dev/null 2>&1
ip link del vswitch1 > /dev/null 2>&1
sysctl -a | grep "proxy_arp" | awk '{print $1}' | xargs -L1 -I % sysctl -w %=0 > /dev/null 2>&1
sysctl -a | grep "proxy_ndp" | awk '{print $1}' | xargs -L1 -I % sysctl -w %=0 > /dev/null 2>&1

### NAT // ###
#/ ipv4 nat
iptables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
#/ ipv6 nat
ip6tables -t nat -D POSTROUTING -o "$GETINTERFACE" -j MASQUERADE >/dev/null 2>&1
### // NAT ###

### RP_FILTER // ###
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null 2>&1
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null 2>&1
sysctl -w net.ipv4.conf."$GETINTERFACE".rp_filter=0 >/dev/null 2>&1
#/ sysctl -w net.ipv4.conf.managed.rp_filter=0 >/dev/null 2>&1
#/ sysctl -w net.ipv4.conf.managed1.rp_filter=0 >/dev/null 2>&1
#/ sysctl -w net.ipv4.conf.vswitch0.rp_filter=0 >/dev/null 2>&1
#/ sysctl -w net.ipv4.conf.vswitch1.rp_filter=0 >/dev/null 2>&1
#
# checkhard lxc-to-go-ci
CHECKLXCTOGOCI=$(basename $0)
if [ "$CHECKLXCTOGOCI" = "lxc-to-go-ci.sh" ];then
   : # dummy
else
   if [ -e "$UDEVNET" ]; then
      sysctl -w net.ipv4.conf."$GETBRIDGEPORT0".rp_filter=0 >/dev/null 2>&1
   fi
fi
### // RP_FILTER ###

cleanup
checkhard clean up tmp files
### ### ###
echo "" # printf
printf "\033[1;32mlxc-to-go shutdown finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'create')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL3=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL3" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
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
checkhard lxc-to-go environment - stage 2

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
checkhard lxc-to-go environment - stage 3

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

echo "Please enter the new LXC Container name:"
read LXCNAME;
if [ -z "$LXCNAME" ]; then
   echo "[ERROR] empty name"
   exit 1
fi
checkhard lxc-to-go environment - stage 4

CHECKLXCEXIST=$(lxc-ls | grep -c "$LXCNAME")
if [ "$CHECKLXCEXIST" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] lxc already exists!"
   exit 1
fi
checkhard lxc-to-go environment - stage 5

echo ""
echo "Choose the LXC template:"
echo "1) wheezy"
echo "2) jessie"
read LXCCREATETEMPLATE;
   if [ -z "$LXCCREATETEMPLATE" ]; then
      echo "[ERROR] nothing selected"
      exit 1
   fi
case $LXCCREATETEMPLATE in
   1) echo "select: wheezy"
      (lxc-clone -o deb7template -n "$LXCNAME") & spinner $!
      if [ $? -eq 0 ]
      then
         : # dummy
      else
         echo "" # dummy
         echo "[ERROR] lxc-clone failed!"
         read -p "Do you wish to remove this corrupt LXC Container: '"$LXCNAME"' ? (y/n)" LXCCREATEFAILED
         if [ "$LXCCREATEFAILED" = "y" ]; then
            lxc-destroy -n "$LXCNAME"
         fi
         exit 1
      fi
      sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$LXCNAME"/config
      sed -i 's/lxc.network.veth.pair = deb7temp/lxc.network.veth.pair = '"$LXCNAME"'/' /var/lib/lxc/"$LXCNAME"/config
      sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$LXCNAME"/rootfs/etc/network/interfaces
      sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$LXCNAME"/rootfs/etc/network/interfaces
   ;;
   2) echo "select: jessie"
      (lxc-clone -o deb8template -n "$LXCNAME") & spinner $!
      if [ $? -eq 0 ]
      then
         : # dummy
      else
         echo "" # dummy
         echo "[ERROR] lxc-clone failed!"
         read -p "Do you wish to remove this corrupt LXC Container: '"$LXCNAME"' ? (y/n)" LXCCREATEFAILED
         if [ "$LXCCREATEFAILED" = "y" ]; then
            lxc-destroy -n "$LXCNAME"
         fi
         exit 1
      fi
      sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$LXCNAME"/config
      sed -i 's/lxc.network.veth.pair = deb8temp/lxc.network.veth.pair = '"$LXCNAME"'/' /var/lib/lxc/"$LXCNAME"/config
      sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$LXCNAME"/rootfs/etc/network/interfaces
      sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$LXCNAME"/rootfs/etc/network/interfaces
   ;;
esac
checkhard lxc-to-go create - stage 1

### randomized MAC address // ###
#/ RANDOMMAC1=$(shuf -i 10-99 -n 1)
#/ RANDOMMAC2=$(shuf -i 10-99 -n 1)
#/ sed -i 's/aa:bb:01:01:bb:aa/aa:bb:'"$RANDOMMAC1"':'"$RANDOMMAC2"':bb:aa/' /var/lib/lxc/"$LXCNAME"/config
#
#/ CHECKMAC1=$(grep "aa:bb" /var/lib/lxc/"$LXCNAME"/config | sed 's/lxc.network.hwaddr=//')
#/ CHECKMAC2=$(grep -c "$CHECKMAC1" /var/lib/lxc/*/config | egrep -v ":0")
#/ if [ -z "$CHECKMAC2" ]; then
#/    : # dummy
#/ else
#/    sed -i 's/aa:bb:01:01:bb:aa/aa:bb:'"$RANDOMMAC1"':'"$RANDOMMAC2"':bb:aa/' /var/lib/lxc/"$LXCNAME"/config
#/    echo "try random mac for the second time"
#/ fi
### // randomized MAC address ###

echo "$LXCNAME" > /var/lib/lxc/"$LXCNAME"/rootfs/etc/hostname

echo ""
read -p "Do you wish to start this LXC Container: "$LXCNAME" ? (y/n) " LXCSTART
if [ "$LXCSTART" = "y" ]; then
   #/screen -d -m -S "$LXCNAME" -- lxc-start -n "$LXCNAME"
### fix //
   if [ "$DEBIAN" = "ubuntu" ]
   then
      screen -d -m -S "$LXCNAME" -- lxc-start -n "$LXCNAME" -F
   else
      screen -d -m -S "$LXCNAME" -- lxc-start -n "$LXCNAME"
   fi
### // fix
  echo ""
  echo "... starting screen session ..."
  sleep 1
  screen -list | grep "$LXCNAME"
  echo ""
checkhard lxc-to-go create - stage 2

### flavor hooks // ###
#
read -p "Do you wanna use 'flavor hooks' ? (y/n) " FLAVOR
if [ "$FLAVOR" = "y" ]; then
   #
   LXCCREATENAME="$LXCNAME"
   export LXCCREATENAME
   : # dummy
   echo "" # dummy
   (sleep 15) & spinner $!
   echo "" # dummy
   : # dummy
   ###
      echo "" # dummy
         "$DIR"/hooks/hook_flavor.sh
      echo "" # dummy
   ###
   unset LXCCREATENAME
else
   : # dummy
   #
fi
checkhard lxc-to-go create - stage 3
#
### // flavor hooks ###

  printf "\033[1;32mlxc-to-go create finished.\033[0m\n"
else
  echo ""
  printf "\033[1;32mlxc-to-go create finished.\033[0m\n"
fi

cleanup
checkhard clean up tmp files
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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'delete')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL4=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL4" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKCONTAINER3=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKCONTAINER3" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 2

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

lxc-ls | egrep -v "managed|deb7template|deb8template" | tr '\n' ' '
echo "" # dummy

echo "" # dummy
echo "Please enter the LXC Container name to DESTROY:"
read LXCDESTROY
if [ -z "$LXCDESTROY" ]; then
   echo "[ERROR] empty name"
   exit 1
fi
checkhard lxc-to-go delete - stage 1

if [ "$LXCDESTROY" = "managed" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't destroy this essential LXC Container, if you have any problems, delete it with 'lxc-destroy -n managed' and repeat the bootstrap\033[0m\n"
   exit 1
fi
checkhard lxc-to-go delete - stage 2

if [ "$LXCDESTROY" = "deb7template" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't destroy this essential LXC Container, if you have any problems, delete it with 'lxc-destroy -n deb7template' and repeat the bootstrap\033[0m\n"
   exit 1
fi
checkhard lxc-to-go delete - stage 3

if [ "$LXCDESTROY" = "deb8template" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't destroy this essential LXC Container, if you have any problems, delete it with 'lxc-destroy -n deb8template' and repeat the bootstrap\033[0m\n"
   exit 1
fi
checkhard lxc-to-go delete - stage 4

### FORWARDING // ###
echo "" # dummy
sleep 5
CHECKFORWARDINGFILE="/etc/lxc-to-go/portforwarding.conf"
if [ -e "$CHECKFORWARDINGFILE" ]; then
   # ipv4 //
   lxc-ls --active --fancy | grep "RUNNING" | egrep -v "managed|deb7template|deb8template" | awk '{print $1,$3}' | grep "$LXCDESTROY" | egrep -v "-" > /etc/lxc-to-go/tmp/lxc.ipv4.del.tmp
   #/ single port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.del.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | sed '/,/d' | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.del.list.s.tmp
   #/ multi port support
   awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,$3,h[$1]}' /etc/lxc-to-go/tmp/lxc.ipv4.del.tmp /etc/lxc-to-go/portforwarding.conf | sort | uniq -u | sed 's/://' | grep "," | grep "192.168" > /etc/lxc-to-go/tmp/lxc.ipv4.del.list.m.tmp
   #
   ### set iptable rules // ###
   #/ single port support
   (
   while read -r line
   do
      set -- $line
      #
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$3":"$2" > /dev/null 2>&1
      #
      CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
      #
      ### set iptable rules on HOST // ###
      if [ "$CHECKENVIRONMENT" = "proxy" ]; then
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
         iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
      fi
      ### // set iptable rules on HOST ###
      #
   done < "/etc/lxc-to-go/tmp/lxc.ipv4.del.list.s.tmp"
   )
   #/ multi port support
   DELMULTIPORTSUPPORTFILE="/etc/lxc-to-go/tmp/lxc.ipv4.del.list.m.tmp"
   if [ -z "$DELMULTIPORTSUPPORTFILE" ]; then
      : # dummy
   else
      #/ dirty but functional (up to 20 ports)
      cat /etc/lxc-to-go/tmp/lxc.ipv4.del.list.m.tmp | awk '{print $3,$2}' | sed 's/,/ /g' > /etc/lxc-to-go/tmp/lxc.ipv4.del.list.m.dirty.tmp
      (
      while read -r line
      do
           set -- $line
           ###/ delete MPORTS /###
           #/ MPORT 1
           lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
           lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$2" -j DNAT --to-destination "$1":"$2" > /dev/null 2>&1
           #/ MPORT 2
           if [ ! -z "$3" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$3" -j DNAT --to-destination "$1":"$3" > /dev/null 2>&1
           fi
           #/ MPORT 3
           if [ ! -z "$4" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$4" -j DNAT --to-destination "$1":"$4" > /dev/null 2>&1
           fi
           #/ MPORT 4
           if [ ! -z "$5" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$5" -j DNAT --to-destination "$1":"$5" > /dev/null 2>&1
           fi
           #/ MPORT 5
           if [ ! -z "$6" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$6" -j DNAT --to-destination "$1":"$6" > /dev/null 2>&1
           fi
           #/ MPORT 6
           if [ ! -z "$7" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$7" -j DNAT --to-destination "$1":"$7" > /dev/null 2>&1
           fi
           #/ MPORT 7
           if [ ! -z "$8" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$8" -j DNAT --to-destination "$1":"$8" > /dev/null 2>&1
           fi
           #/ MPORT 8
           if [ ! -z "$9" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "$9" -j DNAT --to-destination "$1":"$9" > /dev/null 2>&1
           fi
           #/ MPORT 9
           if [ ! -z "${10}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${10}" -j DNAT --to-destination "$1":"${10}" > /dev/null 2>&1
           fi
           #/ MPORT 10
           if [ ! -z "${11}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${11}" -j DNAT --to-destination "$1":"${11}" > /dev/null 2>&1
           fi
           #/ MPORT 11
           if [ ! -z "${12}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${12}" -j DNAT --to-destination "$1":"${12}" > /dev/null 2>&1
           fi
           #/ MPORT 12
           if [ ! -z "${13}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${13}" -j DNAT --to-destination "$1":"${13}" > /dev/null 2>&1
           fi
           #/ MPORT 13
           if [ ! -z "${14}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${14}" -j DNAT --to-destination "$1":"${14}" > /dev/null 2>&1
           fi
           #/ MPORT 14
           if [ ! -z "${15}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${15}" -j DNAT --to-destination "$1":"${15}" > /dev/null 2>&1
           fi
           #/ MPORT 15
           if [ ! -z "${16}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${16}" -j DNAT --to-destination "$1":"${16}" > /dev/null 2>&1
           fi
           #/ MPORT 16
           if [ ! -z "${17}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${17}" -j DNAT --to-destination "$1":"${17}" > /dev/null 2>&1
           fi
           #/ MPORT 17
           if [ ! -z "${18}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${18}" -j DNAT --to-destination "$1":"${18}" > /dev/null 2>&1
           fi
           #/ MPORT 18
           if [ ! -z "${19}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${19}" -j DNAT --to-destination "$1":"${19}" > /dev/null 2>&1
           fi
           #/ MPORT 19
           if [ ! -z "${20}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${20}" -j DNAT --to-destination "$1":"${20}" > /dev/null 2>&1
           fi
           #/ MPORT 20
           if [ ! -z "${21}" ]; then
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p tcp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
              lxc-attach -n managed -- iptables -t nat -D PREROUTING -i eth0 -p udp --dport "${21}" -j DNAT --to-destination "$1":"${21}" > /dev/null 2>&1
           fi
           #
           CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')
           #
           ### set iptable rules on HOST // ###
           if [ "$CHECKENVIRONMENT" = "proxy" ]; then
              ###/ delete MPORTS /###
              #/ MPORT 1
              iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
              iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$2" -j DNAT --to-destination 192.168.253.254:"$2" > /dev/null 2>&1
              #/ MPORT 2
              if [ ! -z "$3" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$3" -j DNAT --to-destination 192.168.253.254:"$3" > /dev/null 2>&1
              fi
              #/ MPORT 3
              if [ ! -z "$4" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$4" -j DNAT --to-destination 192.168.253.254:"$4" > /dev/null 2>&1
              fi
              #/ MPORT 4
              if [ ! -z "$5" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$5" -j DNAT --to-destination 192.168.253.254:"$5" > /dev/null 2>&1
              fi
              #/ MPORT 5
              if [ ! -z "$6" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$6" -j DNAT --to-destination 192.168.253.254:"$6" > /dev/null 2>&1
              fi
              #/ MPORT 6
              if [ ! -z "$7" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$7" -j DNAT --to-destination 192.168.253.254:"$7" > /dev/null 2>&1
              fi
              #/ MPORT 7
              if [ ! -z "$8" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$8" -j DNAT --to-destination 192.168.253.254:"$8" > /dev/null 2>&1
              fi
              #/ MPORT 8
              if [ ! -z "$9" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "$9" -j DNAT --to-destination 192.168.253.254:"$9" > /dev/null 2>&1
              fi
              #/ MPORT 9
              if [ ! -z "${10}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${10}" -j DNAT --to-destination 192.168.253.254:"${10}" > /dev/null 2>&1
              fi
              #/ MPORT 10
              if [ ! -z "${11}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${11}" -j DNAT --to-destination 192.168.253.254:"${11}" > /dev/null 2>&1
              fi
              #/ MPORT 11
              if [ ! -z "${12}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${12}" -j DNAT --to-destination 192.168.253.254:"${12}" > /dev/null 2>&1
              fi
              #/ MPORT 12
              if [ ! -z "${13}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${13}" -j DNAT --to-destination 192.168.253.254:"${13}" > /dev/null 2>&1
              fi
              #/ MPORT 13
              if [ ! -z "${14}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${14}" -j DNAT --to-destination 192.168.253.254:"${14}" > /dev/null 2>&1
              fi
              #/ MPORT 14
              if [ ! -z "${15}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${15}" -j DNAT --to-destination 192.168.253.254:"${15}" > /dev/null 2>&1
              fi
              #/ MPORT 15
              if [ ! -z "${16}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${16}" -j DNAT --to-destination 192.168.253.254:"${16}" > /dev/null 2>&1
              fi
              #/ MPORT 16
              if [ ! -z "${17}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${17}" -j DNAT --to-destination 192.168.253.254:"${17}" > /dev/null 2>&1
              fi
              #/ MPORT 17
              if [ ! -z "${18}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${18}" -j DNAT --to-destination 192.168.253.254:"${18}" > /dev/null 2>&1
              fi
              #/ MPORT 18
              if [ ! -z "${19}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${19}" -j DNAT --to-destination 192.168.253.254:"${19}" > /dev/null 2>&1
              fi
              #/ MPORT 19
              if [ ! -z "${20}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${20}" -j DNAT --to-destination 192.168.253.254:"${20}" > /dev/null 2>&1
              fi
              #/ MPORT 20
              if [ ! -z "${21}" ]; then
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
                 iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport "${21}" -j DNAT --to-destination 192.168.253.254:"${21}" > /dev/null 2>&1
              fi
           fi
      ### // set iptable rules on HOST ###
      #
      done < "/etc/lxc-to-go/tmp/lxc.ipv4.del.list.m.dirty.tmp"
      )
   fi
   ### // set iptable rules ###
   # // ipv4
   ###
   sed -i '/'"$LXCDESTROY"'/d' "$CHECKFORWARDINGFILE"
   ###
fi
checkhard lxc-to-go portforwarding
### // FORWARDING ###

   echo "" # dummy
   echo "... shutdown & delete the lxc container ..."
   lxc-stop -n "$LXCDESTROY" -k > /dev/null 2>&1
   lxc-destroy -n "$LXCDESTROY"
checkhard lxc-to-go destroy

cleanup
checkhard clean up tmp files
### ### ###
echo ""
printf "\033[1;32mlxc-to-go delete finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'show')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL4=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL4" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

echo "" # dummy
printf "\033[1;33m LXC-to-Go HOST: \033[0m\n"
lxc-ls --fancy --fancy-format name,state,ipv4,ipv6,pid,memory,ram,swap | egrep -v "deb7template|deb8template"

CHECKMANAGEDLXC=$(lxc-ls --active | grep -c "managed")
if [ "$CHECKMANAGEDLXC" = "1" ]
then
   echo "" # dummy
   printf "\033[1;33m LXC-in-LXC (managed): \033[0m\n"
   lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then lxc-ls --fancy --fancy-format name,state,ipv4,ipv6,pid,memory,ram,swap; fi'
fi

### ### ###
echo ""
printf "\033[1;32mlxc-to-go show finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'login')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
CHECKLXCINSTALL4=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL4" ]; then
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
checkhard lxc-to-go environment - stage 1
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKCONTAINER1=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKCONTAINER1" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 2

CHECKLXCSTARTMANAGED=$(lxc-ls --active | grep -c "managed")
if [ "$CHECKLXCSTARTMANAGED" = "1" ]; then
   : # dummy
else
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 3

CHECKLXCSTART1=$(lxc-ls | egrep -v -c "managed|deb7template|deb8template")
if [ "$CHECKLXCSTART1" = "0" ]; then
   echo "" # dummy
   printf "\033[1;31mCan't find any additional LXC Container, execute the 'create' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 4

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### ### ###

lxc-ls --active | egrep -v "deb7template|deb8template" | tr ' ' '\n' | nl | sed 's/$/ off/' > /etc/lxc-to-go/tmp/loginlist1.tmp

dialog --radiolist "Choose one lxc container:" 45 80 60 --file /etc/lxc-to-go/tmp/loginlist1.tmp 2>/etc/lxc-to-go/tmp/loginlist2.tmp
loginlist1=$?
case $loginlist1 in
    0)
       : # dummy
       awk 'NR==FNR {h[$1] = $2; next} {print $1,$2,h[$1]}' /etc/lxc-to-go/tmp/loginlist1.tmp /etc/lxc-to-go/tmp/loginlist2.tmp | awk '{print $2}' | sed 's/"//g' > /etc/lxc-to-go/tmp/loginlist3.tmp
       echo "" # dummy
       echo "" # dummy
       lxc-attach -n "$(cat /etc/lxc-to-go/tmp/loginlist3.tmp)"
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

### ### ###
echo ""
printf "\033[1;32mlxc-to-go login finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
'lxc-in-lxc-webpanel')
### stage1 // ###
case $DEBIAN in
debian|linuxmint|ubuntu|devuan)
### stage2 // ###
checkrootuser
checkdebiandistribution
### // stage2 ###
#
### stage3 // ###
#
#// can't support devuan without systemd cgroups management yet :(
if [ "$DEBIAN" = "devuan" ]
then
   printf "\033[1;31m Sorry we can't support Devuan without SystemD Cgroups Management :( \033[0m\n"
   exit 1
fi

CHECKLXCINSTALL4=$(/usr/bin/which lxc-checkconfig)
if [ -z "$CHECKLXCINSTALL4" ]; then
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 1

DIALOG=$(/usr/bin/which dialog)
if [ -z "$DIALOG" ]; then
   echo "<--- --- --->"
   echo "need dialog"
   echo "<--- --- --->"
   apt-get update
   apt-get -y install dialog
   echo "<--- --- --->"
fi
checkhard lxc-to-go environment - stage 2
#
### stage4 // ###
#
### ### ### ### ### ### ### ### ###

CHECKLXCSTARTMANAGED=$(lxc-ls --active | grep -c "managed")
if [ "$CHECKLXCSTARTMANAGED" = "1" ]; then
   : # dummy
else
   echo "" # dummy
   printf "\033[1;31mLXC 'managed' doesn't run, execute the 'bootstrap' command at first\033[0m\n"
   exit 1
fi
checkhard lxc-to-go environment - stage 3

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

### ### ###

# install LXC-Web-Panel
lxc-attach -n managed -- /bin/sh -c 'if [ -e "/srv/lwp" ]; then rm -f /NOWEBPANEL; else touch /NOWEBPANEL; fi'
CHECKWEBPANEL="/var/lib/lxc/managed/rootfs/NOWEBPANEL"
if [ -e "$CHECKWEBPANEL" ]
then
   echo "" # dummy
   echo "... installing LXC-Web-Panel for LXC-inside-LXC Scheme ..."
   echo "" # dummy
   # LXC-Web-Panel Package
   lxc-attach -n managed -- apt-get -y update
   lxc-attach -n managed -- apt-get -y install git python-dev
   #/lxc-attach -n managed -- /bin/sh -c 'mkdir -p /github; cd /github; git clone https://github.com/plitc/LXC-Web-Panel.git; cd /github/LXC-Web-Panel; chmod 0755 /github/LXC-Web-Panel/install.sh; /github/LXC-Web-Panel/install.sh'
   lxc-attach -n managed -- /bin/sh -c 'mkdir -p /github; cd /github; git clone https://github.com/plitc/lxc-to-go-webpanel.git; cd /github/lxc-to-go-webpanel; chmod 0755 /github/lxc-to-go-webpanel/install.sh; /github/lxc-to-go-webpanel/install.sh'
   # LXC-inside-LXC
   echo "" # dummy
   echo "... prepare LXC-inside-LXC ..."
   echo "" # dummy
   sed -i 's/lxc.tty=2/lxc.tty=99/g' /var/lib/lxc/managed/config
   sed -i '/lxc.cgroup.devices/d' /var/lib/lxc/managed/config
   # prepare LXC Environment
   GETKERNELRELEASE=$(uname -r)
   cp -prf /boot/config-"$GETKERNELRELEASE" /var/lib/lxc/managed/rootfs/boot
   if [ $? -eq 0 ]
   then
      lxc-attach -n managed -- apt-get -y update
      lxc-attach -n managed -- apt-get -y install lxc bridge-utils screen
   else
      echo "[ERROR] can't copy config-$GETKERNELRELEASE to /var/lib/lxc/managed/rootfs/boot"
      # clean up
      lxc-attach -n managed -- /etc/init.d/lwp stop
      lxc-attach -n managed -- rm -rf /srv/lwp
      exit 1
   fi
   #// for AMD64 or PowerPC Environment
   CHECKYABOOT3=$(/usr/bin/dpkg -l | grep yaboot | awk '{print $2}')
   if [ -z "$CHECKYABOOT3" ]
   then
      #// for amd64
      (cp -prf /var/cache/lxc/debian/rootfs-wheezy-amd64 /var/lib/lxc/managed/rootfs/var/cache/lxc/debian) & spinner $!
   else
      #// for powerpc
      (cp -prf /var/cache/lxc/debian/rootfs-wheezy-ppc /var/lib/lxc/managed/rootfs/var/cache/lxc/debian) & spinner $!
   fi
cat << "MANAGEDLXCINLXC" > /var/lib/lxc/managed/rootfs/etc/network/interfaces
### ### ### lxc-to-go // ### ### ###
#
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
iface eth0 inet6 manual

auto eth1
iface eth1 inet manual
iface eth1 inet6 manual

auto lxc-in-lxc
iface lxc-in-lxc inet static
   up ip link set dev lxc-in-lxc up
   bridge_ports none
   bridge_hello 2
   bridge_fd 15
   bridge_maxwait 15
   #/bridge_hw
   bridge_stp no
   address 192.168.252.254
   netmask 255.255.255.0
   broadcast 192.168.252.255
   #/gateway
   post-up sysctl -w net.ipv4.conf.lxc-in-lxc.forwarding=1
   post-up sysctl -w net.ipv6.conf.lxc-in-lxc.forwarding=1
#
### ### ### // lxc-to-go ### ### ###
# EOF
MANAGEDLXCINLXC
   ### LXC Template fixes // ###

   # from: /usr/share/lxc/templates
   # lxc-alpine  lxc-altlinux  lxc-archlinux  lxc-busybox  lxc-centos  lxc-cirros  lxc-debian  lxc-debian-wheezy  lxc-download  lxc-fedora  lxc-gentoo  lxc-openmandriva  lxc-opensuse  lxc-oracle  lxc-plamo  lxc-sshd  lxc-ubuntu  lxc-ubuntu-cloud

   # BROKEN: lxc-alpine
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-alpine

   # BROKEN: lxc-altlinux
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-altlinux

   # BROKEN: lxc-archlinux
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-archlinux

   # NOT TESTED: lxc-busybox
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-busybox

   # FIXED: lxc-centos
   lxc-attach -n managed -- apt-get -y install yum
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-centos

   # NOT TESTED: lxc-cirros
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-cirros

   # DEFAULT: lxc-debian
   #// for PowerPC Environment
   CHECKYABOOT4=$(/usr/bin/dpkg -l | grep yaboot | awk '{print $2}')
   if [ -z "$CHECKYABOOT4" ]
   then
      : # dummy
   else
      cp -prf /usr/share/lxc/templates/lxc-debian-wheezy /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-debian
   fi

   # DEFAULT: lxc-debian-wheezy

   # CLI only: lxc-download

   # FIXED/BROKEN: lxc-fedora
   lxc-attach -n managed -- apt-get -y install curl
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-fedora

   # BROKEN: lxc-gentoo
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-gentoo

   # BROKEN: lxc-openmandriva
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-openmandriva

   # BROKEN: lxc-opensuse
   lxc-attach -n managed -- apt-get -y install zypper
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-opensuse

   # BROKEN: lxc-oracle
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-oracle

   # NOT TESTED: lxc-plamo
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-plamo

   # BROKEN: lxc-sshd
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-sshd

   # BROKEN: lxc-ubuntu
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-ubuntu

   # BROKEN: lxc-ubuntu-cloud
   rm -rf /var/lib/lxc/managed/rootfs/usr/share/lxc/templates/lxc-ubuntu-cloud

   ### // LXC Template fixes ###
   ### lxc-in-lxc host resolve // ###
   CHECKETCHOSTS1=$(grep -c "lxc-to-go" /etc/hosts)
   if [ "$CHECKETCHOSTS1" = "0" ]
   then
      echo "192.168.253.254   lxc-to-go" >> /etc/hosts
   fi
   ### // lxc-in-lxc host resolve ###
   "$DIR"/lxc-to-go.sh stop
   "$DIR"/lxc-to-go.sh shutdown
   echo "" # dummy
   printf "\033[1;32m LXC-Web-Panel:   http://192.168.253.254:5000 \033[0m\n"
   printf "\033[1;32m Username:        admin \033[0m\n"
   printf "\033[1;32m Password:        admin \033[0m\n"
   printf "\033[1;32m default gateway: 192.168.252.254 \033[0m\n"
else
   #/iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p tcp --dport 5000 -j DNAT --to-destination 192.168.253.254:5000 > /dev/null 2>&1 # HOST
   #/iptables -t nat -D PREROUTING -i "$GETINTERFACE" -p udp --dport 5000 -j DNAT --to-destination 192.168.253.254:5000 > /dev/null 2>&1 # HOST
   #/iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport 5000 -j DNAT --to-destination 192.168.253.254:5000 # HOST
   #/iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport 5000 -j DNAT --to-destination 192.168.253.254:5000 # HOST
   echo "" # dummy
   printf "\033[1;32m LXC-Web-Panel:   http://192.168.253.254:5000 \033[0m\n"
   printf "\033[1;32m Username:        admin \033[0m\n"
   printf "\033[1;32m Password:        admin \033[0m\n"
   printf "\033[1;32m default gateway: 192.168.252.254 \033[0m\n"
fi
checkhard lxc-to-go lxc-inside-lxc webpanel

### ### ###
echo ""
printf "\033[1;32mlxc-to-go (lxc-inside-lxc) webpanel finished.\033[0m\n"
### ### ###

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
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
#
### // stage1 ###
;;
*)
printf "\033[1;31mWARNING: lxc-to-go is experimental and its not ready for production. Do it at your own risk.\033[0m\n"
echo "" # usage
echo "usage: $0 { bootstrap | start | stop | shutdown | create | delete | show | login | lxc-in-lxc-webpanel }"
;;
esac
exit 0
### ### ### PLITC ### ### ###
# EOF
