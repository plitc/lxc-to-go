#!/bin/sh
### ### ### lxc-to-go // ### ### ###
#// version: 1.0

RUN(){
   # execute commands inside the lxc template
   lxc-attach -n "$LXCCREATENAME" -- "$@"
}

CHECK(){
   # check state
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
   # break
   sleep 2
   echo ""
   echo "---> next step: "$@" <---"
   echo ""
}

### ### ### // lxc-to-go ### ### ###
# EOF
