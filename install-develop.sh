#!/bin/bash
################################################################################
#                                                                              #
#                      Domogik installation script                             #
#                                                                              #
#                      ~~~~~~ www.domogik.org ~~~~~                            #
#                                                                              #
################################################################################
#
# This script will automatically :
# - download the domogik related packages (domogik, domogik-mq, domoweb)
# - install the needed prerequisites
# - install and configure the domogik related packaged
#
################################################################################



################################################################################
# Configuration part
################################################################################

DOMOGIK_RELEASE=develop
DOMOGIK_MQ_RELEASE=1.4
DOMOWEB_RELEASE=develop




################################################################################
# Url building
################################################################################

DOMOGIK_PACKAGE=https://github.com/domogik/domogik/archive/${DOMOGIK_RELEASE}.tar.gz
DOMOGIK_MQ_PACKAGE=https://github.com/domogik/domogik-mq/archive/${DOMOGIK_MQ_RELEASE}.tar.gz
DOMOWEB_PACKAGE=https://github.com/domogik/domoweb/archive/${DOMOWEB_RELEASE}.tar.gz




################################################################################
# Some global variables
################################################################################

# These variables should not be changed!

TMP_FOLDER=/tmp
INSTALL_FOLDER=/opt




################################################################################
# Functions - utilities
################################################################################

# title
#
# Display a title
function title() {
    printf '[xxxxxxx] %*s\n' "$(( ${COLUMNS:-$(tput cols)} - 10 ))" '' | tr ' ' - | tr 'x' ' '
    echo "[       ]        $*"
    printf '[xxxxxxx] %*s\n' "$(( ${COLUMNS:-$(tput cols)} - 10 ))" '' | tr ' ' - | tr 'x' ' '
}


# info
#
# Display messages in yellow
function info() {
    echo -e "[ INFO  ] \e[93m$*\e[39m"
}


# ok
#
# Display messages in green
function ok() {
    echo -e "[ OK    ] \e[92m$*\e[39m"
}


# error
#
# Display messages in red
function error() {
    #echo -e "[ ERROR ] \e[91m$*\e[39m"
    echo -e "[ \e[5mERROR\e[0m ] \e[91m$*\e[39m"
}


# abort
#
# display an error message and exit the installation script
function abort() {
    error $*
    echo -e "[ \e[5mABORT\e[0m ] \e[91mThe installation is aborted due to the previous error!\e[39m"
    exit 1
}



# download
#
# $1 : url of a package to download
# $2 : target file name
#
# Download a resource in the TMP_FOLDER with $2 as filename
function download() {
    url=$1
    filename=$2
    filename_path=${TMP_FOLDER}/${filename}

    info "Start downloading '${url}' to '${filename_path}'..."

    if [ -f ${filename_path} ] ; then
        info "A previous downloaded file exists : '${filename_path}'. Removing it..."
        rm -f ${filename_path}
        if [ $? -eq 0 ] ; then
            ok "Previous downloaded file '${filename_path}' deleted."
        else
            abort "Previous downloaded file '${filename_path}' can't be deleted."
        fi
    fi

    wget -O ${filename_path} ${url}
    if [ $? -ne 0 ] ; then
        abort "Package download in error."
    fi
    if [ -f ${filename_path} ] ; then
        ok "Package download done."
    else
        abort "Package download done but the target file '${filename_path}' is not present."
    fi
}





################################################################################
# Functions - checks
################################################################################

# is_using_root_or_abort
#
# Abort if the user is not root 
function is_using_root_or_abort() {
    [[ $EUID -ne 0 ]] && abort "This installation script must be running as root or sudo"
}


# is_linux
#
# Return 0 if the OS is a Linux system
function is_linux() {
    info "OS is : $(uname)"
    [[ "X$(uname)" == "XLinux" ]] && return 0
    return 1
}


# is_linux_kernel_compliant_or_abort
#
# Abort if the kernel is >= 3.9
function is_linux_kernel_compliant_or_abort() {
    major=$(uname -r | cut -d"." -f1)
    minor=$(uname -r | cut -d"." -f2)
    info "Kernel release is : ${major}.${minor}" 
    abort_msg="The current kernel release (${major}.${minor}) is not compliant with the minimum expected (3.9)"
    [[ ${major} -lt 3 ]] && abort ${abort_msg}
    [[ ${major} -eq 3 ]] && [[ ${minor} -lt 9 ]] && abort ${abort_msg}
}


################################################################################
# Functions - installation
################################################################################

# download_all_packages
#
# Download a resource in the TMP_FOLDER with $2 as filename
function download_all_packages() {
    title "Downloading Domogik-mq ${DOMOGIK_MQ_RELEASE} package"
    download ${DOMOGIK_MQ_PACKAGE} domogik-mq.tar.gz

    title "Downloading Domogik ${DOMOGIK_RELEASE} package"
    download ${DOMOGIK_PACKAGE} domogik.tar.gz

    title "Downloading Domoweb ${DOMOWEB_RELEASE} package"
    download ${DOMOWEB_PACKAGE} domoweb.tar.gz
}


# install_domogik_mq
#
# Install the Domogik-MQ package
function install_domogik_mq() {
    error "TODO"

}













################################################################################
# MAIN                                   
################################################################################


################################################################################
# 0. do some checks (distribution version, python version, root, free space, ...)
# TODO
# TODO : for gunicorn, check kernel >= 3.9

# check if executed with root or sudo
is_using_root_or_abort

# check OS and kernel
[[ is_linux -eq 0 ]] && is_linux_kernel_compliant_or_abort 

################################################################################
# 1. check if something is already installed, if so, do some backups

################################################################################
# 2. install the prerequisites
# TODO

################################################################################
# 3. download the needed packages
#download_all_packages

################################################################################
# 4. install Domogik-MQ
install_domogik_mq

################################################################################
# 5. test the Domogik-MQ installation
# TODO

################################################################################
# 6. install Domogik
# TODO

################################################################################
# 7. test the Domogik installation
# TODO
# check crontab are installed





ok "Installation finished with SUCCESS"
