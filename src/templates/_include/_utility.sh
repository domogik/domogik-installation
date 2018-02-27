################################################################################
# Functions - utilities
################################################################################


# build informations
#
# This function returns some informations about when the final script is build.
# This function code is updated by the build.sh script in src/
function build_informations() {
    echo "                  Build : %% build_informations %%"  # BUILD_INFORMATIONS
}

# display some informations
function display_informations() {
    echo ""
    # Ascii art generator : http://patorjk.com/software/taag/#p=display&f=Crazy&t=Domogik
    echo "                  ______                            _ _    ";
    echo "                  |  _  \                          (_) |   ";
    echo "                  | | | |___  _ __ ___   ___   __ _ _| | __";
    echo "                  | | | / _ \| '_ \` _ \ / _ \ / _\` | | |/ /";
    echo "                  | |/ / (_) | | | | | | (_) | (_| | |   < ";
    echo "                  |___/ \___/|_| |_| |_|\___/ \__, |_|_|\_\  ";
    echo "                                               __/ |       ";
    echo "                                              |___/        ";

    echo ""
    echo ""
    build_informations
    echo ""
}

# test_pip
#
# Test pip by doing a pip search command
# This is done because we encountered some pip issues with some users
function test_pip() {
    pip_test_cmd="pip search simplejson"
    info "Testing silently the 'pip' tool with the comment '${pip_test_cmd}'..."
    $pip_test_cmd > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        ok "Pip is working correctly"
    else
        error "Pip seems not to work. Executing again the command to display you the output for analysis :"
        $pip_test_cmd 
        abort "Please check your configuration. This is not a Domogik issue, this is a Pip isssue."
    fi
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

