#!/bin/bash

provider=$1
fr=$2
lr=$3

C='\033[0;94m'
G='\033[0;32m'
L='\033[38;5;135m'
R='\033[91m'
NC='\033[0m'

if [[ $(df -T / | awk 'NR==2 {print $2}') == "zfs" ]]; then
        dump_dir="/var/lib/vz/dump"
	else
        dump_dir="/var/lib/pve/local-btrfs/dump"
fi 

# Überprüfen, ob die Argumente gesetzt sind
if [ -z "$provider" ] || [ -z "$fr" ] || [ -z "$lr" ]; then
    echo -e "${R}Error: At least one variable empty!${NC}"
    exit 1
fi

## Wenn die VMs vor dem Restore zerstört werden sollen, hier die Kommentierungen entfernen:
# echo -e "${C}Destroying VM$([[ $fr != $lr ]] && echo s)${NC}"
for i in $(seq $fr $lr); do 
    sudo qm stop ${provider}0${provider}00$i 
    #  sudo qm destroy ${provider}0${provider}00$i
    done

# Überprüfen, ob das Verzeichnis existiert
if [ ! -d "$dump_dir" ]; then
    echo -e "${R}Error: Directory $dump_dir does not exist.${NC}"
    exit 1
fi

# Durchlaufen aller .vma-Dateien im Verzeichnis
for vma_file in "$dump_dir"/*.vma; do
    # VMID aus dem Dateinamen extrahieren
    vmid=$(basename "$vma_file" | grep -oP '(?<=vzdump-qemu-)\d+')

    # Überprüfen, ob die VMID extrahiert wurde
    if [ -z "$vmid" ]; then
        echo -e "${R}Error: Could not extract VMID from $vma_file.${NC}"
        exit 1
    fi

    provider_vmid="${provider}0${provider}001"

    # Prüfen, ob es sich um einen Router von fr bis lr handelt
    for i in $(seq $fr $lr); do
        router_vmid="${provider}0${provider}00$i"
        if [[ "$vmid" == "$router_vmid" ]]; then
            echo -e "${C}Restoring router $vmid ...${NC}"
            sudo qmrestore "$vma_file" "$vmid" --force
            break
        fi
    done
done

echo -e "${C}Starting router$([[ $fr != $lr ]] && echo s) and updating SSH known hosts${NC}"
for r in $(seq $fr $lr); do
    vmid="${provider}0${provider}00${r}"
    sudo qm start "$vmid"
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ""
done

if [[ $fr == $lr ]]; then
	echo -e "${G}Restore of router ${L}p${provider}r${fr}v${G} executed successfully!${NC}"
else
	echo -e "${G}Restore of routers ${L}p${provider}r${fr}v${G} to ${L}p${provider}r${lr}v${G} executed successfully!${NC}"
fi
