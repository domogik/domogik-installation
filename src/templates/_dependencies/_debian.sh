########################################
#  Install dependencies for Debian 8.6 #
########################################
# All the lines are prefixed by '   ' to get a final script more clear to read

    # is a package installed ?
    function dpkg_l() {
        info "Check if the package '$1' is installed..."
        dpkg -l $1
        if [[ $? -eq 0 ]] ; then
            ok "Package '$1' is already installed."
            return 0
        else
            info "Package '$1' is NOT installed."
            return 1
        fi
    }

    # install a package
    function apt_get_install() {
        echo "" # a blank to be clearer
        info "Installing the package(s) : $*"
        apt-get -y install $*
        [[ $? -ne 0 ]] && abort "The installation of the package(s) '$*' failed."
        ok "Package(s) '$*' installed."
    }

    # remove a package
    function apt_get_remove() {
        echo "" # a blank to be clearer
        info "Removing the package(s) : $*"
        apt-get -y remove $*
        [[ $? -ne 0 ]] && abort "The removal of the package(s) '$*' failed."
        ok "Package(s) '$*' removed."
    }

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
        
        ### Install packages
        # LSB release
        #Domogik installation script uses the ``lsb_release -si`` command to check which Linux distribution you are using. Some Linux distribution has not this package instlled by default. This is the case for **Raspbian** for example.
        #
        #On all Debian-based distributions (Raspbian for example), we install the **lsb-release** package
        
        apt_get_install lsb-release
        
        ### Python 2.7 and related
        apt_get_install python2.7
        apt_get_install python2.7-dev python-pip

        # Remove python-cffi
        # python-cffi is installed with the previous command (apt-get -y install python2.7-dev python-pip)...
        #
        # This is needed because the installed release is too old (8.6.1) and used by python instead of the one installed with pip
        # which is needed to avoid some setuptools_ext import error.
        apt_get_remove python-cffi

        # Various dependencies
        apt_get_install libssl-dev
        apt_get_install zlib1g-dev
        apt_get_install libffi-dev

        # Sound related dependencies
        apt_get_install sox libttspico-utils
        
        ### MySQL/MariaDB server
        
        # in case, this is not already installed, we automatically set a root password during installation
        export DEBIAN_FRONTEND=noninteractive

        # For debug, if needed :
        #echo "PASSWORD=$MYSQL_ROOT_PASSWORD"

        # Non working part : the password is not used, but this way, no password is set so this is quite usefull during the install!
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
    
        # Install only Maria DB is not already installed
        dpkg_l mariadb-server
        [[ $? -ne 0 ]] && apt_get_install mariadb-server

        # TODO : check the mariadb release also ?
        
    else 
        echo "Not a Debian"
    fi
