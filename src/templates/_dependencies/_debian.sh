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
        
        ### Install packages
        # LSB release
        #Domogik installation script uses the ``lsb_release -si`` command to check which Linux distribution you are using. Some Linux distribution has not this package instlled by default. This is the case for **Raspbian** for example.
        #
        #On all Debian-based distributions (Raspbian for example), we install the **lsb-release** package
        
        apt-get -y install lsb-release
        
        ### Python 2.7 and related
        apt-get -y install python2.7
        apt-get -y install python2.7-dev python-pip

        # Remove python-cffi
        # python-cffi is installed with the previous command (apt-get -y install python2.7-dev python-pip)...
        #
        # This is needed because the installed release is too old (8.6.1) and used by python instead of the one installed with pip
        # which is needed to avoid some setuptools_ext import error.
        apt-get -y remove python-cffi

        # Various dependencies
        apt-get -y install libssl-dev
        apt-get -y install zlib1g-dev
        apt-get -y install libffi-dev

        # Sound related dependencies
        apt-get -y install sox libttspico-utils
        
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
    
        apt-get -y install mariadb-server
        
    else 
        echo "Not a Debian"
    fi
