#!/bin/bash
################################################################################
#                                                                              #
#                      Logging, stdout/stderr library                          #
#                                                                              #
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


# prompt
#
# Display messages in blue
function prompt() {
    echo -e "[       ] \e[35m$*\e[39m"
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

