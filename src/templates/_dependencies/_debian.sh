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
        info "If the package mariadb-server is not installed, this password will be used during its installation as database root password : '${MYSQL_ROOT_PASSWORD}'"


        ### Update the packages list
        apt-get update
        
    if [[ 1 -eq 0 ]] ; then ######## DEBUG
        
        ### LSB release
        #Domogik installation script uses the ``lsb_release -si`` command to check which Linux distribution you are using. Some Linux distribution has not this package instlled by default. This is the case for **Raspbian** for example.
        #
        #On all Debian-based distributions (Raspbian for example), we install the **lsb-release** package
        
        apt-get -y install lsb-release
        
        ### Python 2.7 and related
        apt-get -y install python2.7
        apt-get -y install python2.7-dev python-pip
        pip install netifaces
        pip install sphinx-better-theme
        
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
        
        
    fi ######## DEBUG
    
    
        ### MySQL/MariaDB server
        
        # in case, this is not already installed, we automatically set a root password during installation
        export DEBIAN_FRONTEND=noninteractive
        debconf-set-selections <<< "mariadb-server/root_password password $MYSQL_ROOT_PASSWORD"
        debconf-set-selections <<< "mariadb-server/root_password_again password $MYSQL_ROOT_PASSWORD"
    
    
        apt-get -y install mariadb-server
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        # TODO : how to not prompt the user for a mysql admin password on install ?
        
    else 
        echo "Not a Debian"
        exit 1
    fi
