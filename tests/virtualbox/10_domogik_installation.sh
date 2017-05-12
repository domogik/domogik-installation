#!/bin/bash

TEST_FOLDER=$(dirname $0)/../
. ${TEST_FOLDER}/lib/log.sh
. ${TEST_FOLDER}/lib/virtualbox.sh

VMName=Test
VMLogin=root
VMPassword=osboxes.org
VMSshPort=22222



####################################################################################################
# Utility functions
####################################################################################################

# TODO : move in library
function execute_in_vm() {
    CMD="$*"
    info "Execute command in VM : $CMD"
    sshpass -p "${VMPassword}" ssh -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${VMLogin}@127.0.0.1 -p ${VMSshPort} "$CMD"
    res=$? 
    [[ $res -ne 0 ]] && error "Error while executing the command!"
    return $res
}




####################################################################################################
# Main
####################################################################################################

### restore the snapshot
title "Prepare the VM"
info "Restore the snapshot"
VBoxManage controlvm "${VMName}"  savestate
[[ $? -ne 0 ]] && info "Unable to suspend the VM : maybe it was already stopped..."
VBoxManage snapshot "${VMName}" restore step0
[[ $? -ne 0 ]] && abort "Error while restoring the snapshot"
start_vm "${VMName}" "${VMLogin}" "${VMPassword}" "${VMSshPort}"
[[ $? -ne 0 ]] && abort "Error while restarting the VM from the snapshot"


### launch the install
title "Execute the installer"
info "Download installer..."
execute_in_vm "cd /tmp ; wget https://raw.githubusercontent.com/domogik/domogik-installation/master/install-develop.sh -O install-develop.sh"
[[ $? -ne 0 ]] && abort "Aborting due to previous error"

execute_in_vm "cd /tmp ; chmod +x install-develop.sh"
[[ $? -ne 0 ]] && abort "Aborting due to previous error"

info "Launch the installer..."
execute_in_vm "cd /tmp ; ./install-develop.sh"
[[ $? -ne 0 ]] && abort "Aborting due to previous error"

