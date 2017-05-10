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

# TODO
# - manage backups to avoid to much disk usage
# - check the port opened before install and if so, request to stop domogik
# - check for some already existing config element
#   - if some exists, handle them
#   - check for database
# - let's encrypt ?
# - crontab
# - do already existing configuration backup ?
# - option to skip db backup ?



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
# Functions - includes
################################################################################


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

################################################################################
# Functions - utilities
################################################################################


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



# extract_package
#
# Extract a tgz file in a directory (and do backup + chown stuff)
#
# $1 : name of the component (used for dipslay only)
# $2 : installation folder
# $3 : backup folder
# $4 : package file (tar.gz)
function extract_package() {
    component=$1
    inst_folder=$2
    bck_folder=$3
    tgz_file=$4

    # backup old install
    if [[ -d ${inst_folder} ]] ; then
        info "The ${component} installation folder '${inst_folder}' already exists. Renaming it as '${bck_folder}'..."
        mv ${inst_folder} ${bck_folder}
        [[ $? -ne 0 ]] && abort "Error while moving '${inst_folder}' as '${bck_folder}'"
        ok "... ok"
    fi

    # extract the package
    info "Extract the package :"
    info "- creating the folder '${inst_folder}'..."
    mkdir -p ${inst_folder}
    [[ $? -ne 0 ]] && abort "Error while creating the folder : '${inst_folder}'"
    ok "  ... ok"
    info "- applying grants on '${inst_folder}' to the user '${INSTALL_USER}:${INSTALL_GROUP}'..."
    chown -R ${INSTALL_USER}:${INSTALL_GROUP} ${inst_folder}
    [[ $? -ne 0 ]] && abort "Error while settings grants to '${INSTALL_USER}:${INSTALL_GROUP}' to the folder : '${inst_folder}'"
    ok "  ... ok"
    info "- extracting the archive '${tgz_file}' to '${inst_folder}'..."
    tar xf ${tgz_file} -C ${inst_folder} --strip 1
    [[ $? -ne 0 ]] && abort "Error while extracting '${tgz_file}' to the installation folder : '${inst_folder}'"
}


# get_uuid
#
# Display an uuid. It is not hardware related!
function get_uuid() {
    python -c 'import sys,uuid; sys.stdout.write(uuid.uuid4().hex)'
}


# get_host_uuid
#
# Display an uuid related to the hardware
function get_host_uuid() {
    python -c 'import sys,uuid; sys.stdout.write(str(uuid.getnode()))'
}

# generate_random_password
#
# Generate sort of a random password
function generate_random_password() {
    python -c 'import sys,uuid; sys.stdout.write(str(uuid.getnode()))'
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
# Some global variables
################################################################################

# These variables should not be changed!

INSTALL_USER=domogik
INSTALL_GROUP=domogik
INSTALL_FOLDER=/opt/dmgtest

TMP_FOLDER=/tmp
TMP_DOMOGIK_MQ_PACKAGE=domogik-mq-${DOMOGIK_MQ_RELEASE}.tar.gz
TMP_DOMOGIK_PACKAGE=domogik-${DOMOGIK_RELEASE}.tar.gz
TMP_DOMOWEB_PACKAGE=domoweb-${DOMOWEB_RELEASE}.tar.gz

# default values for MySQL/MariaDB
MYSQL_ROOT_PASSWORD=$(generate_random_password) # this is needed only if no MySQL/MariaDB server is installed.
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_DATABASE=domogiktest
MYSQL_LOGIN=domogiktest
MYSQL_PASSWORD=domogikpass




################################################################################
# Functions - installation
################################################################################


# if_initd_stop_all
#
# Check if some /etc/init.d/ files exist. If so, stop the related components
function if_initd_stop_all() {
    # Domogik
    if [[ -f /etc/init.d/domogik ]] ; then
        info "Try to stop the already installed Domogik (this will also stop Domogik-MQ and the xPL hub)..."
        /etc/init.d/domogik stop
    fi
    if [[ -f /etc/rc.d/domogik ]] ; then
        info "Try to stop the already installed Domogik (this will also stop Domogik-MQ and the xPL hub)..."
        /etc/rc.d/domogik stop
    fi

    # Domoweb
    if [[ -f /etc/init.d/domoweb ]] ; then
        info "Try to stop the already installed Domoweb..."
        /etc/init.d/domoweb stop
    fi
    if [[ -f /etc/rc.d/domoweb ]] ; then
        info "Try to stop the already installed Domoweb..."
        /etc/rc.d/domoweb stop
    fi
}


# download_all_packages
#
# Download a resource in the TMP_FOLDER with $2 as filename
function download_all_packages() {
    title "Downloading Domogik-mq ${DOMOGIK_MQ_RELEASE} package"
    download ${DOMOGIK_MQ_PACKAGE} ${TMP_DOMOGIK_MQ_PACKAGE}

    title "Downloading Domogik ${DOMOGIK_RELEASE} package"
    download ${DOMOGIK_PACKAGE} ${TMP_DOMOGIK_PACKAGE}

    title "Downloading Domoweb ${DOMOWEB_RELEASE} package"
    download ${DOMOWEB_PACKAGE} ${TMP_DOMOWEB_PACKAGE}
}


# create_user_if_needed
#
# Create the domogik user if it does not exists yet
function create_user_if_needed() {
    info "Checking if the user '${INSTALL_USER}' exists..."
    id -u ${INSTALL_USER} > /dev/null 
    if [[ $? -ne 0 ]] ; then
        info "... the user does not exists."

        info "Creating the user '${INSTALL_USER}'..."
        useradd -M ${INSTALL_USER}
        [[ $? -ne 0 ]] && abort "Error while create the user '${INSTALL_USER}'"
        ok "... ok"
    
        info "Setting a default password '${INSTALL_USER}' to the new user '${INSTALL_USER}'"
        echo -e "${INSTALL_USER}\n${INSTALL_USER}" | passwd ${INSTALL_USER}
        [[ $? -ne 0 ]] && abort "Error while setting the default password '${INSTALL_USER}' to the user '${INSTALL_USER}'"
        ok "... ok"
    else
        info "... the user already exists."
    fi

}


# prepare_install_folder
#
# Prepare the installation folder
function prepare_install_folder() {
    ### create if needed
    info "Check if the folder '${INSTALL_FOLDER}' exists and has the appropriate grants..."
    if [[ ! -d ${INSTALL_FOLDER} ]] ; then   
        info "The folder does not exists..."
        info "- creating '${INSTALL_FOLDER}'"
        mkdir -p ${INSTALL_FOLDER}
        [[ $? -ne 0 ]] && abort "Error while creating the installation folder : '${INSTALL_FOLDER}'"
        ok "  ... ok"
        info "- applying grants on '${INSTALL_FOLDER}' to the user '${INSTALL_USER}:${INSTALL_GROUP}'"
        # the command is after the if as done in all cases
    else
        ok "The installation folder '${INSTALL_FOLDER}' already exists"
        info "Just in case, we will reset the folder '${INSTALL_FOLDER}' grants to the user '${INSTALL_USER}:${INSTALL_GROUP}'"
        # the command is after the if as done in all cases
    fi
    chown ${INSTALL_USER}:${INSTALL_GROUP} ${INSTALL_FOLDER}
    [[ $? -ne 0 ]] && abort "Error while settings grants to '${INSTALL_USER}:${INSTALL_GROUP}' to the installation folder : '${INSTALL_FOLDER}'"
    ok "  ... ok"
    [[ $? -ne 0 ]] && abort "Error while applying grants on '${INSTALL_FOLDER}' to the user '${INSTALL_USER}'"

    ### test if the install user can create a file
    dummy_file=${INSTALL_FOLDER}/dummy
    info "Try to create a dummy file '${dummy_file}' to check the installation folder (and after delete it)..."
    su ${INSTALL_USER} -c "touch ${dummy_file}"
    [[ $? -ne 0 ]] && abort "The user '${INSTALL_USER}' is not able to create the file '${dummy_file}'.
    su ${INSTALL_USER} -c "rm -f ${dummy_file}"
    [[ $? -ne 0 ]] && abort "The user '${INSTALL_USER}' is not able to delete the file '${dummy_file}'.
    ok "... ok"
    
}


# prepare_database
#
# Check the database server availibility and if needed, create the database
function prepare_database() {
    ### test the domogik login+password
    # we do a 'create database if not exists' just in case the user would have been manually created, 
    # but not the database... in fact, this should not be needed
    info "Try to access the database server '${MYSQL_HOST}:${MYSQL_PORT}' with user='${MYSQL_LOGIN}' and password='****'..."
    # first, check if the mysql client is installed
    which mysql > /dev/null
    [[ $? -ne 0 ]] && abort "The 'mysql' command is not found : please check that the MySQL client is installed on your server."  
    # then, we can test the database connection
    mysql -u${MYSQL_LOGIN} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} -P${MYSQL_PORT} <<EOF
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        exit
EOF
    if [[ $? -eq 0 ]] ; then
        ok "... ok"
    else
        info "... unable to connect! (this is not an error if this is your first installation)"
        info "We will create a database and an account for Domogik :"
        info "- database = ${MYSQL_DATABASE}"
        info "- login = ${MYSQL_LOGIN}"
        info "- password = ${MYSQL_PASSWORD}"
        ask_db_root_password="yes"

        # first, we try to login with no mysql root password in case no password is configured...
        info "Try to login in database as the 'root' database user with no password..."
        mysql -uroot -h${MYSQL_HOST} -P${MYSQL_PORT} <<EOF
            exit
EOF
        if [[ $? -eq 0 ]] ; then
            # ok, we can use this password
            db_root_password=""
            ask_db_root_password="no"
            ok "... ok : we can login as root user on database without password."
        else
            info "... not possible."
        fi

        # then, we try to login with the generated mysql root password in case we installed ourself the server engine
        info "Try to login in database as the 'root' database user with generated password '${MYSQL_ROOT_PASSWORD}'..."
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} -h${MYSQL_HOST} -P${MYSQL_PORT} <<EOF
            exit
EOF
        if [[ $? -eq 0 ]] ; then
            # ok, we can use this password
            db_root_password=${MYSQL_ROOT_PASSWORD}
            ask_db_root_password="no"
            ok "... ok : As we installed the database server automatically we known the database root password, so we autologin. Just in case you need it, the password is '${MYSQL_ROOT_PASSWORD}'."
        else
            info "... not possible."
        fi

        # if we are not able to login automatically, we ask the password
        if [[ "x${ask_db_root_password}" == "xyes" ]] ; then
            # let's ask the user the password
            # TODO : or find a way to get the root password ?
            info "... not possible : it seems you already had the database server installed."
            info "To create the domogik database, we need you to login as the 'root' user of the database."
            prompt "Database root password (hidden) : "
            read -s db_root_password
        fi
        
        info "Creating the database '${MYSQL_DATABASE}' and the user='${MYSQL_LOGIN}' with password='${MYSQL_PASSWORD}'..."
        [ -z "${db_root_password}" ] && mysql_connection="-uroot" || mysql_connection="-uroot -p${db_root_password}"
        mysql ${mysql_connection} -h${MYSQL_HOST} -P${MYSQL_PORT} <<EOF
            CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
            GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* to ${MYSQL_LOGIN}@localhost IDENTIFIED BY '${MYSQL_PASSWORD}';
EOF
        [[ $? -ne 0 ]] && abort "Error while creating the database or user."
        info "... ok"

    fi

    ### Test the created database
    info "Check the database user '${MYSQL_LOGIN}' can access the Domogik database '${MYSQL_DATABASE}' by creating and dropping a dummy table..."
    mysql -u${MYSQL_LOGIN} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} -P${MYSQL_PORT} <<EOF
        use '${MYSQL_DATABASE}';
        CREATE TABLE IF NOT EXISTS dummy (test int);
        DROP TABLE dummy;
EOF
    [[ $? -ne 0 ]] && abort "Error while accessing the databse."
    ok "... ok"
}



# install_pip_dependencies
#
# $1 : component name
# $2 : path in which the requirements.txt is available
#
# Install pip dependencies
function install_pip_dependencies() {
    component="$1"
    inst_folder="$2"
    info "Running : 'cd $2 && pip install -r requirements.txt' ..."
    cd $2 && pip install -r requirements.txt
    [[ $? -ne 0 ]] && abort "Error while installing requirements with pip."
    ok "... ok"
}



# install_domogik_mq
#
# Install the Domogik-MQ package
function install_domogik_mq() {
    component="Domogik-MQ"
    inst_folder=${INSTALL_FOLDER}/domogik-mq/
    bck_folder=${INSTALL_FOLDER}/domogik-mq-$(date "+%Y%m%d.%H%M%S")/
    tgz_file=${TMP_FOLDER}/${TMP_DOMOGIK_MQ_PACKAGE}

    title "Extract the ${component} package"
    extract_package "${component}" "${inst_folder}" "${bck_folder}" "${tgz_file}"

    title "Install the pip dependencies for the ${component} package"
    install_pip_dependencies ${component} ${inst_folder}

    title "Install the ${component} package"
    cd ${inst_folder}
    python ./install.py --daemon \
                        --user ${INSTALL_USER} \
                        --command-line 
    [[ $? -ne 0 ]] && abort "Error while installing the package ${component}"
}



# install_domogik
#
# Install the Domogik package
function install_domogik() {
    component="Domogik"
    inst_folder=${INSTALL_FOLDER}/domogik/
    bck_folder=${INSTALL_FOLDER}/domogik-$(date "+%Y%m%d.%H%M%S")/
    tgz_file=${TMP_FOLDER}/${TMP_DOMOGIK_PACKAGE}

    title "Extract the ${component} package"
    extract_package "${component}" "${inst_folder}" "${bck_folder}" "${tgz_file}"

    title "Install the pip dependencies for the ${component} package"
    install_pip_dependencies ${component} ${inst_folder}

    title "Install the ${component} package"
    cd ${inst_folder}
    info "Start installing ${component}. If you have already a database, a backup will be done. This step can take some time!" 
    python install.py --user ${INSTALL_USER} \
                      --command-line \
                      --domogik_log_level debug \
                      --no-create-database \
                      --database_name ${MYSQL_DATABASE} \
                      --database_user ${MYSQL_LOGIN} \
                      --database_password ${MYSQL_PASSWORD} \
                      --database_host ${MYSQL_HOST} \
                      --admin_secret_key $(get_uuid) \
                      --metrics_id $(get_host_uuid) \
                      --hub_log_level info \
                      --hub_log_bandwidth False \
                      --hub_log_invalid_data True 
    [[ $? -ne 0 ]] && abort "Error while installing the package ${component}"
}





# install_domoweb
#
# Install the Domoweb package
function install_domoweb() {
    component="Domoweb"
    inst_folder=${INSTALL_FOLDER}/domoweb/
    bck_folder=${INSTALL_FOLDER}/domoweb-$(date "+%Y%m%d.%H%M%S")/
    tgz_file=${TMP_FOLDER}/${TMP_DOMOWEB_PACKAGE}

    title "Extract the ${component} package"
    extract_package "${component}" "${inst_folder}" "${bck_folder}" "${tgz_file}"

    title "Install the pip dependencies for the ${component} package"
    install_pip_dependencies ${component} ${inst_folder}

    title "Install the ${component} package"
    cd ${inst_folder}
    info "Start installing ${component}..."
    python install.py --user ${INSTALL_USER} \
                      --command-line 
    [[ $? -ne 0 ]] && abort "Error while installing the package ${component}"
}



# install_domogik_package
#
# $1 : package id formatted as 'type_name'
# $2 : package url
#
# Install a given domogik package from an url
function install_domogik_package() {
    # First, check if the package is not already installed : 
    # We don't install or upgrade an already installed package release!

    su - ${INSTALL_USER} -c "dmg_package " | grep "Package $1" 
    if [[ $? -eq 0 ]] ; then
        info "The package '$1' is already installed. Skipping the installation..."
        return
    fi

    # Install the package
    info "Installing the package '$1' from url '$2'..."
    su - ${INSTALL_USER} -c "dmg_package --install '$2'"
    if [[ $? -eq 0 ]] ; then
        ok "... ok"
    else
        abort "Error while installing the package '$1' from url '$2'"
    fi
}







################################################################################
# MAIN                                   
################################################################################


################################################################################
# 0. do some checks (distribution version, python version, root, free space, ...)
# TODO
# TODO : for gunicorn, check kernel >= 3.9
# TODO :get arch, dsitribution

title "Check the prerequisites"

# check if executed with root or sudo
is_using_root_or_abort

# check OS and kernel
# needed by :
# - gunicorn (needs >= 3.9)
[[ is_linux -eq 0 ]] && is_linux_kernel_compliant_or_abort 

################################################################################
# 1. check if something is already installed, if so, do some backups

# if some init.d script are present, make sure all is stopped
if_initd_stop_all

# TODO : handle systemd 
#if_systemd_stop_all

################################################################################
# 2. install the prerequisites
# TODO

title "Install the dependencies"

########################################
#  Install dependencies for Debian 8.6 #
########################################

    # All the lines are prefixed by '   ' to get a final script more clear to read

    ### Check if this is a Debian release
    OS="unknown"
    RELEASE=""
    if [[ -f /etc/debian_version ]] ; then
        OS=debian
    fi
    
    ### If Debian, process...
    if [[ "x$OS" == "xdebian" ]] ; then
        # The mysql root password should be defined in the global install script.
        # We override it here only for local test purpose
        [[ -z "$MYSQL_ROOT_PASSWORD" ]] && MYSQL_ROOT_PASSWORD="rootpasswordtochange2017"
        info "If the package mariadb-server is not installed, this password will be used during its installation as the database root password : '${MYSQL_ROOT_PASSWORD}'"


        ### Update the packages list
        apt-get update
        
        ### LSB release
        #Domogik installation script uses the ``lsb_release -si`` command to check which Linux distribution you are using. Some Linux distribution has not this package instlled by default. This is the case for **Raspbian** for example.
        #
        #On all Debian-based distributions (Raspbian for example), we install the **lsb-release** package
        
        apt-get -y install lsb-release
        
        ### Python 2.7 and related
        apt-get -y install python2.7
        apt-get -y install python2.7-dev python-pip

        # TODO : DEL
        # TODO : DEL
        # TODO : DEL
        #pip install netifaces
        #pip install sphinx-better-theme

        ### Zlib dev files
        apt-get install zlib1g-dev

        ### Libffi-dev
        apt-get install libffi-dev
        
        ### Specific about Debian stable (8.6)
        # If you are using a Debian stable, you will need to install a more recent release of **alembic** related package. You will have to follow these steps.
        #
        #Create the file **/etc/apt/apt.conf.d/99defaultrelease**. It must contain : ::
        #
        #    APT::Default-Release "stable";
        #
        #Create the file **/etc/apt/sources.list.d/stable.list** : ::
        #
        #    deb     http://ftp.fr.debian.org/debian/    stable main contrib non-free
        #    deb-src http://ftp.fr.debian.org/debian/    stable main contrib non-free
        #    deb     http://security.debian.org/         stable/updates  main contrib non-free
        #
        #Create the file **/etc/apt/sources.list.d/testing.list** : ::
        #
        #    deb     http://ftp.fr.debian.org/debian/    testing main contrib non-free
        #    deb-src http://ftp.fr.debian.org/debian/    testing main contrib non-free
        #    deb     http://security.debian.org/         testing/updates  main contrib non-free
        #
        #Then run : ::
        #
        #    $ sudo apt-get update
        #    $ sudo apt-get -t testing install python-sqlalchemy python-editor python-sqlalchemy python-alembic
        #
        #It will install the needed packages from the testing repository.
        
        
    
        ### MySQL/MariaDB server
        
        # in case, this is not already installed, we automatically set a root password during installation
        export DEBIAN_FRONTEND=noninteractive

        echo "PASSWORD=$MYSQL_ROOT_PASSWORD"
        #debconf-set-selections <<< "mariadb-server/root_password password $MYSQL_ROOT_PASSWORD"
        #debconf-set-selections <<< "mariadb-server/root_password_again password $MYSQL_ROOT_PASSWORD"
        # TODO : handle this : 
        # debconf: unable to initialize frontend: Dialog
        # debconf: (TERM is not set, so the dialog frontend is not usable.)
        # debconf: falling back to frontend: Readline
        # debconf: unable to initialize frontend: Readline
        # debconf: (This frontend requires a controlling tty.)
        # debconf: falling back to frontend: Teletype
        # dpkg-preconfigure: unable to re-open stdin: 

    
    
        apt-get -y install mariadb-server
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        
    else 
        echo "Not a Debian"
        exit 1
    fi





title "Create the user and installation folder"

# create user
create_user_if_needed
# /opt + grants
prepare_install_folder

# check if the database server is up and if the database already exists
title "Prepare the database"
prepare_database


################################################################################
# 3. download the needed packages

# TODO : option to avoid download (for test mainly)
download_all_packages

################################################################################
# 4. install Domogik-MQ
install_domogik_mq

################################################################################
# 5. test the Domogik-MQ installation
# TODO

################################################################################
# 6. install Domogik

# TODO : check for default database or create database
install_domogik

################################################################################
# 7. test the Domogik installation
# TODO
# check crontab are installed


################################################################################
# 8. install Domoweb

install_domoweb

################################################################################
# 7. test the Domoweb installation
# TODO


################################################################################
# 80. Install some default packages

title "Install packages..."
install_domogik_package plugin_weather "http://github.com/fritz-smh/domogik-plugin-weather/archive/master.zip"


################################################################################
# 99. start all
# TODO : check if init.d or systemd

title "Start Domogik (and Domogik MQ in the same time)..."
/etc/init.d/domogik start

title "Start Domoweb..."
/etc/init.d/domoweb start


ok "Installation finished with SUCCESS"