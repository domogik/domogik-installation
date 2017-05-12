#!/bin/bash

TEST_FOLDER=$(dirname $0)/../
. ${TEST_FOLDER}/lib/log.sh
. ${TEST_FOLDER}/lib/virtualbox.sh

# TODO : make this parameters in an external file
VMName=Test
OS=Debian
VDI="/media/stock/VMs/Debian 8.6.0 (32bit).vdi"
VboxFolder="/tmp/vbox/"
VMLogin=root
VMPassword=osboxes.org
SSH_WAIT=60

# TODO
# - check if sshpass is installed






### Configure the machine folder####################################################################
VBoxManage setproperty machinefolder "${VboxFolder}"

### Try to stop the VM if already running ##########################################################
# TODO : add a check
title "Try to stop the already running VM '${VMName}'..."
info "- stop VM..."
VBoxManage controlvm "${VMName}" poweroff
info "- unregister VM..."
VBoxManage unregistervm "${VMName}" 

### Clean the old machine folder ###################################################################
title "Clean the old machine folder"
info "Cleaning '${VboxFolder}'..."
rm -Rf ${VboxFolder}/*
[[ $? -ne 0 ]] && abort "Error while doing 'rm -Rf ${VboxFolder}/*'"
ok "... ok"

### then, create the VM ############################################################################
title "Create the VM..."
info "- create and register VM..."
VBoxManage createvm --name "${VMName}" --ostype "${OS}" --register

info "- configure VM cpu and memory..."
VBoxManage modifyvm "${VMName}" --memory 1536 --vram 16 --usb on --acpi on --boot1 dvd 

info "- configure VM network (nat)..."
VBoxManage modifyvm "${VMName}" --nic1 nat

info "- configure the port forwarding..."
VBoxManage modifyvm "${VMName}" --natpf1 "guestssh,tcp,,22222,,22"
#VBoxManage modifyvm "${VMName}" --natpf1 "guestdmg1,tcp,,50506,,40406"
#VBoxManage modifyvm "${VMName}" --natpf1 "guestdmg2,tcp,,50505,,40405"
#VBoxManage modifyvm "${VMName}" --natpf1 "guestdmw,tcp,,50504,,40404"

# TODO : not needed ??? why ??
info "- set a SATA controller..."
VBoxManage storagectl "${VMName}" --name "SATA Controller" --add sata

info "- attach the VDI file..."
VBoxManage storageattach "${VMName}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VDI}"


### start the VM###################################################################################
title "Starting the VM ${VMName}"
info "Start the VM..."

# start in background (headless mode)
info "- start VM"
start_vm "${VMName}" "${VMLogin}" "${VMPassword}" 22222



# TODO : function to test a port is open
#printf "  "
#until exec 6<>/dev/tcp/127.0.0.1/22111 ; do 
#    printf "."
#    sleep 5
#done
#echo ""


# take a snapshot
info "- Take a snapshot 'step0'"
VBoxManage snapshot "${VMName}" take step0


ok "Done"

