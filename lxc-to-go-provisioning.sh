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

#// function: spinner
spinner()
{
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

#// function: run script as root
checkrootuser()
{
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// function: check debian based distributions
checkdebiandistribution()
{
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
               echo "[ERROR] We currently only support: Debian 7,8,9 (testing) / Linux Mint Debian Edition (LMDE 2 Betsy) and Ubuntu Desktop 15.10+"
               exit 1
            fi
         fi
      fi
   fi
fi
}
### // stage0 ###

### stage1 // ###
if [ "$DEBIAN" = "debian" -o "$DEBIAN" = "linuxmint" -o "$DEBIAN" = "ubuntu" ]
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

GETINTERFACE=$(grep -s "INTERFACE" /etc/lxc-to-go/lxc-to-go.conf | sed 's/INTERFACE=//')

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

#/ check name - alphanumeric
cname="$(echo "$name" | sed -e 's/[^[:alnum:]]//g')"
if [ "$cname" != "$name" ] ; then
   echo "" # dummy
   echo "[ERROR] string -name '"$name"' has characters which are not alphanumeric"
   exit 1
fi

#/ check template - empty argument
if [ -z "$template" ]; then
   echo "" # dummy
   echo "[ERROR] choose for template argument (deb7/deb8)"
   exit 1
fi

#/ check template - argument
ctemplate="$(echo "$template" | sed 's/deb7//g' | sed 's/deb8//g')"
if [ -z "$ctemplate" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for template argument (deb7/deb8)"
   exit 1
fi

#/ check hooks - empty argument
if [ -z "$hooks" ]; then
   echo "" # dummy
   echo "[ERROR] choose for hooks argument (yes/no)"
   exit 1
fi

#/ check hooks - argument
chooks="$(echo "$hooks" | sed 's/yes//g' | sed 's/no//g')"
if [ -z "$chooks" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for hooks argument (yes/no)"
   exit 1
fi

#/ check port - empty argument
if [ -z "$port" ]; then
   echo "" # dummy
   echo "[ERROR] choose a port number or alternative use 'lxc-to-go create'"
   exit 1
fi

#/ check port - numeric
cport="$(echo "$port" | sed 's/[^0-9,]*//g')"
if [ "$cport" != "$port" ] ; then
   echo "" # dummy
   echo "[ERROR] string -port '"$port"' has characters which are not numeric"
   exit 1
fi

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

CHECKPORTRESERVATION=$(grep -sc "$port" /etc/lxc-to-go/portforwarding.conf)
if [ "$CHECKPORTRESERVATION" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] port already reserved"
   exit 1
fi

#/ check start - empty argument
if [ -z "$start" ]; then
   echo "" # dummy
   echo "[ERROR] choose for start argument (yes/no)"
   exit 1
fi

#/ check start - argument
cstart="$(echo "$start" | sed 's/yes//g' | sed 's/no//g')"
if [ -z "$cstart" ] ; then
   : # dummy
else
   echo "" # dummy
   echo "[ERROR] choose for start argument (yes/no)"
   exit 1
fi

### create // ###

CHECKLXCEXIST=$(lxc-ls | grep -c "$name")
if [ "$CHECKLXCEXIST" = "1" ]; then
   echo "" # dummy
   echo "[ERROR] lxc already exists!"
   exit 1
fi

###

if [ "$template" = "deb7" ]; then
   (lxc-clone -o deb7template -n "$name") & spinner $!
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
   sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.veth.pair = deb7temp/lxc.network.veth.pair = '"$name"'/' /var/lib/lxc/"$name"/config
   sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   echo "$name" > /var/lib/lxc/"$name"/rootfs/etc/hostname
fi

if [ "$template" = "deb8" ]; then
   (lxc-clone -o deb8template -n "$name")& spinner $!
   if [ $? -eq 0 ]
   then
      : # dummy
   else
      echo "" # dummy
      echo "[ERROR] lxc-clone to "$name" failed!"
         lxc-destroy -n "$name"
      exit 1
   fi
   sed -i 's/lxc.network.name = eth1/lxc.network.name = eth0/' /var/lib/lxc/"$name"/config
   sed -i 's/lxc.network.veth.pair = deb8temp/lxc.network.veth.pair = '"$name"'/' /var/lib/lxc/"$name"/config
   sed -i 's/iface eth0 inet manual/iface eth0 inet dhcp/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   sed -i 's/iface eth0 inet6 manual/iface eth0 inet6 auto/' /var/lib/lxc/"$name"/rootfs/etc/network/interfaces
   echo "$name" > /var/lib/lxc/"$name"/rootfs/etc/hostname
fi

### create // ###

CHECKENVIRONMENT=$(grep -s "ENVIRONMENT" /etc/lxc-to-go/lxc-to-go.conf | sed 's/ENVIRONMENT=//')

### cleanup // ###
#
CHECKDEB7IF=$(ifconfig | grep -c "deb7temp")
if [ "$CHECKDEB7IF" = "1" ]; then
   ip link set dev deb7temp down
   ip link del deb7temp
fi
CHECKDEB8IF=$(ifconfig | grep -c "deb8temp")
if [ "$CHECKDEB8IF" = "1" ]; then
   ip link set dev deb8temp down
   ip link del deb8temp
fi
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
         echo "" # dummy
      ###
      unset LXCCREATENAME
   fi
fi
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
         echo "" # dummy
      ###
      unset LXCCREATENAME
   fi
fi
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
            #/ single port support
         if [ "$cportmulti2" = "0" ]; then
            # iptables - managed
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "$port" -j DNAT --to-destination "$GETIPV4":"$port"
            lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$port" -j DNAT --to-destination "$GETIPV4":"$port"
            if [ "$CHECKENVIRONMENT" = "server" ]; then
               # iptables - host
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST
               iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "$port" -j DNAT --to-destination 192.168.253.254:"$port" # HOST
            fi
         else
            #/ multi port support
            grep -s "$name" /etc/lxc-to-go/portforwarding.conf | awk '{print $3}' | tr ',' '\n' > /etc/lxc-to-go/tmp/lxc.set.ipv4.multiport.tmp
            cat /etc/lxc-to-go/tmp/lxc.set.ipv4.multiport.tmp | xargs -L1 -I % lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p tcp --dport "%" -j DNAT --to-destination "$GETIPV4":"%"
            cat /etc/lxc-to-go/tmp/lxc.set.ipv4.multiport.tmp | xargs -L1 -I % lxc-attach -n managed -- iptables -t nat -A PREROUTING -i eth0 -p udp --dport "%" -j DNAT --to-destination "$GETIPV4":"%"
            if [ "$CHECKENVIRONMENT" = "server" ]; then
               # iptables - host
               cat /etc/lxc-to-go/tmp/lxc.set.ipv4.multiport.tmp | xargs -L1 -I % iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p tcp --dport "%" -j DNAT --to-destination 192.168.253.254:"%" # HOST
               cat /etc/lxc-to-go/tmp/lxc.set.ipv4.multiport.tmp | xargs -L1 -I % iptables -t nat -A PREROUTING -i "$GETINTERFACE" -p udp --dport "%" -j DNAT --to-destination 192.168.253.254:"%" # HOST
            fi
         fi
      fi
   fi
fi
#
### // FORWARDING ###

### // PROVISIONING ###

### ### ###
echo ""
printf "\033[1;31mlxc-to-go provisioning finished.\033[0m\n"
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
