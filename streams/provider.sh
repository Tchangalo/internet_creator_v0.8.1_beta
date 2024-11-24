#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_TIMEOUT=100

provider=$1
fr=$2   # First Router
lr=$3   # Last Router
startdelay=$4
refresh=$5

le=""   #limit element
for e in $(seq $fr $lr); do
    le+="p${provider}r${e}v,"
done
le=${le%,}
vyos_ansible_limit="-l $le"

C='\033[0;94m'
G='\033[0;32m'
L='\033[38;5;135m'
R='\033[91m'
NC='\033[0m'

sleeping ()
{
    for r in $(seq $2 $3); do
	while sleep 5; do
	    ansible -i ${HOME}/streams/ansible/inventories/inventory${provider}.yaml p${provider}r${r}v -m ping -u vyos | grep -q pong && break
	done
	echo -e "${C}Router ${r} is running${NC}"
    done
}

if [ -z "$provider" ] || [ -z "$fr" ] || [ -z "$lr" ] [ -z "$startdelay" ]; then
    echo -e "${R}Error: At least one variable empty!${NC}"
    exit 1
fi

#destroy and create vms
cd ${HOME}/streams/create-vms/create-vms-vyos/

for r in $(seq $fr $lr); do
	if [[ $(df -T / | awk 'NR==2 {print $2}') == "zfs" ]]; then		
	sudo bash create-vm-vyos_zfs.sh -p ${provider} -r $r
    else
	sudo bash create-vm-vyos_btrfs.sh -p ${provider} -r $r
    fi
done

#start and update ssh known hosts
echo -e "${C}Starting VM$([[ $fr != $lr ]] && echo s) and updating SSH known hosts${NC}"
for r in $(seq $fr $lr); do
    sudo qm start ${provider}0${provider}00${r}
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "10.20.30.${provider}${r}"
    sleep $startdelay
done

#sleeping
echo -e "${C}Waiting for first boot${NC}"
sleeping $provider $fr $lr

#upgrade
if [[ $refresh == 1 ]]; then
	cd ${HOME}/streams/ansible
	rm -rf vyos-files
	mkdir vyos-files
	cd vyos-files

	download_url=$(curl -s https://api.github.com/repos/vyos/vyos-nightly-build/releases/latest | jq -r ".assets[0].browser_download_url")

	echo -e "${C}Waiting for download of latest Vyos version into /home/user/streams/ansible/vyos-files to complete ...${NC}"
	if curl -LO "$download_url"; then
		echo -e "${C}Download completed successfully${NC}"
	else
		echo -e "${R}Download failed. Exiting script${NC}"
		exit 1
	fi
fi

cd ${HOME}/streams/ansible
echo -e "${C}System upgrade${NC}"
ansible-playbook -i inventories/inventory${provider}.yaml vyos_upgrade.yml -e "vyos_version=$(ls -t ${HOME}/streams/ansible/vyos-files/ | head -n 1 | sed -e 's/^vyos-//' | sed -e 's/-amd.*$//')" "$vyos_ansible_limit"

#reboot
echo -e "${C}Second boot${NC}"
echo -e "${C}Shutting down VM$([[ $fr != $lr ]] && echo s)${NC}"
sudo  bash ${HOME}/streams/ks/shutdown.sh $provider $fr $lr
echo -e "${C}Restarting VM$([[ $fr != $lr ]] && echo s)${NC}"
sudo  bash ${HOME}/streams/ks/start.sh $provider $fr $lr $startdelay

#sleeping
echo -e "${C}Waiting ...${NC}"
sleeping $provider $fr $lr

#configure
echo -e "${C}Configuring network${NC}"
ansible-playbook -i inventories/inventory${provider}.yaml setup.yml "$vyos_ansible_limit"

#delete cdrom
echo -e "${C}Deleting cdrom$([[ $fr != $lr ]] && echo s)${NC}"
for r in $(seq $fr $lr); do
    sudo qm set ${provider}0${provider}00${r} --delete ide2
done

#reboot
echo -e "${C}Final reboot${NC}"
sleep 3
echo -e "${C}Shutting down VM$([[ $fr != $lr ]] && echo s)${NC}"
sudo  bash ${HOME}/streams/ks/shutdown.sh $provider $fr $lr
echo -e "${C}Final restart${NC}"
sudo bash ${HOME}/streams/ks/start.sh $provider $fr $lr $startdelay

if [[ $fr == $lr ]]; then
	echo -e "${G}Creation of router ${L}p${provider}r${fr}v${G} executed successfully!${NC}"
else
	echo -e "${G}Creation of routers ${L}p${provider}r${fr}v${G} to ${L}p${provider}r${lr}v${G} executed successfully!${NC}"
fi
echo -e "${C}Wait a minute until the network is running.${NC}"
