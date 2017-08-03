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

{% include './_include/_log.sh' %}
{% include './_include/_utility.sh' %}


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
    info "Running : 'cd $2 && pip install --upgrade -r requirements.txt' ..."
    cd $2 && pip install --upgrade -r requirements.txt
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

{% include './_dependencies/_debian.sh' %}





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
