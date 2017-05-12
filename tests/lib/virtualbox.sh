#!/bin/bash
################################################################################
#                                                                              #
#                      Logging, stdout/stderr library                          #
#                                                                              #
################################################################################

# REQUIRES : include the log.sh library first




# start_vm
#
# Start the VM and check for ssh available
#
# $1 : VM Name
# $2 : Login for ssh
# $3 : Password for ssh
# $4 : Port for ssh
#
# We request no host as the port is NATed on the current host, so host = 127.0.0.1
function start_vm() {
    VMName="$1"
    VMLogin="$2"
    VMPassword="$3"
    VMSshPort="$4"
    SSH_WAIT=60

    info "Start the VM ${VMName}"
    VBoxManage startvm "${VMName}" --type headless
    
    # wait until ssh is available
    info "- wait for ssh..."
    info "    (first wait, for ${SSH_WAIT} seconds, else you could never be able to access ssh over NAT... yeah : WTF? )"
    sleep ${SSH_WAIT}
    info "    (now, do some moe tries...)"
    printf "  "
    until sshpass -p "${VMPassword}" ssh -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${VMLogin}@127.0.0.1 -p ${VMSshPort} "uname -a" > /dev/null 2>&1 ; do
        printf "."
        sleep 10
    done
    echo "" # line return
    ok "- SSH available on the VM."

}
