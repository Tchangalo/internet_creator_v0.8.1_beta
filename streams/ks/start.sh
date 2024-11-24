#!/bin/bash

provider=$1
fr=$2
lr=$3
a=$4

C='\033[0;94m'
R='\033[91m'
NC='\033[0m'

if [ -z "$provider" ] || [ -z "$fr" ] || [ -z "$lr" ] || [ -z "$a" ]; then
  echo -e "${R}Error: At least one variable is empty!${NC}"
  exit 1
fi

for i in $(seq $fr $lr); do 
  sudo qm start ${provider}0${provider}00$i 
  sleep $a
done

# if [[ $fr == $lr ]]; then
# 	echo -e "${C}Start of router p${provider}r${fr}v executed successfully!${NC}"
# else
# 	echo -e "${C}Start of routers p${provider}r${fr}v to p${provider}r${lr}v executed successfully!${NC}"
# fi