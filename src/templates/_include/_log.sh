
# title
#
# Display a title
function title() {
    tput cols > /dev/null 2>&1
    if [[ $? -eq 0 ]] ; then
        # tput cols works, we generate dynamically the width
        printf '[xxxxxxx] %*s\n' "$(( ${COLUMNS:-$(tput cols)} - 10 ))" '' | tr ' ' - | tr 'x' ' '
        echo "[       ]        $*"
        printf '[xxxxxxx] %*s\n' "$(( ${COLUMNS:-$(tput cols)} - 10 ))" '' | tr ' ' - | tr 'x' ' '
    else
        # tput cols does not work (maybe this is run over ssh), we use 80 as width
        printf '[xxxxxxx] %*s\n' "70" '' | tr ' ' - | tr 'x' ' '
        echo "[       ]        $*"
        printf '[xxxxxxx] %*s\n' "70" '' | tr ' ' - | tr 'x' ' '
    fi
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

