#!/bin/bash

provider=$1
fr=$2
lr=$3

C='\033[0;94m'
G='\033[0;32m'
L='\033[38;5;135m'
R='\033[91m'
NC='\033[0m'

if [ -z "$provider" ] || [ -z "$fr" ] || [ -z "$lr" ]; then
    echo -e "${R}Error: At least one variable empty!${NC}"
    exit 1
fi

if [[ $(df -T / | awk 'NR==2 {print $2}') == "zfs" ]]
	then
		sudo mkdir /var/lib/vz/dump
        for i in $(seq $fr $lr)
    	do  
			vmid=${provider}0${provider}0$(printf '%02d' $i)
			echo -e "${C}Backing up router ${vmid}${NC}"
    		sudo vzdump ${provider}0${provider}00$i --dumpdir /var/lib/vz/dump --mode snapshot --compress 0
			sleep 5
    	done
	else
		vmid=${provider}0${provider}0$(printf '%02d' $i)
		echo -e "${C}Backing up router ${vmid}${NC}"
		sudo mkdir /var/lib/pve/local-btrfs/dump
        for i in $(seq $fr $lr)
    	do 
    		sudo vzdump ${provider}0${provider}00$i --dumpdir /var/lib/pve/local-btrfs/dump --mode snapshot --compress 0
			sleep 5
    	done
fi  

if [[ $fr == $lr ]]; then
	echo -e "${G}Backup of router ${L}p${provider}r${fr}v${G} executed successfully!${NC}"
else
	echo -e "${G}Backups of routers ${L}p${provider}r${fr}v${G} to ${L}p${provider}r${lr}v${G} executed successfully!${NC}"
fi