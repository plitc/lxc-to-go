#!/bin/sh
### ### ### lxc-to-go // ### ### ###
#// version: 1.0

RUN(){
   #// execute commands inside the lxc template
   lxc-attach -n "$LXCCREATENAME" -- "$@"
}

CHECK(){
   #// check state
   if [ $? -eq 0 ]
   then
      echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
      sleep 2
   else
      echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
      exit 1
   fi
}

LOL(){
   #// break
   sleep 2
   echo ""
   echo "---> next step: "$@" <---"
   echo ""
}

SPINNER(){
   #// spinner
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

### ### ### // lxc-to-go ### ### ###
# EOF
