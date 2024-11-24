#!/bin/bash

provider=$1
fr=$2
lr=$3

C='\033[0;94m'
R='\033[91m'
NC='\033[0m'

if [ -z "$provider" ] || [ -z "$fr" ] || [ -z "$lr" ]; then
  echo -e "${R}Error: At least one variable is empty!${NC}"
  exit 1
fi

for i in $(seq $fr $lr); do 
  sudo qm stop ${provider}0${provider}00$i
  sudo qm destroy ${provider}0${provider}00$i
done

# if [[ $fr == $lr ]]; then
# 	echo -e "${C}Destruction of router p${provider}r${fr}v executed successfully!${NC}"
# else
# 	echo -e "${C}Destruction of routers p${provider}r${fr}v to p${provider}r${lr}v executed successfully!${NC}"
# fi