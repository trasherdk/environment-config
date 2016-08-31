#!/bin/bash
###############################################
#  Install Packages
#  Michael Pratt <pratt@hablarmierda.net>
###############################################
set -e
ROOTLOCATION=${1}
CURRENTLOCATION="${ROOTLOCATION}/packages"
NOTINSTALLED=()

# Source functions
source "${ROOTLOCATION}/functions.sh"


read -p "Do you want to install system packages? (y/n) " INSTALLPKGS
if [[ "${INSTALLPKGS}" == "n" ]]; then
    exit 0
fi


# Get all packages
LIST=$(grep -v '^$\|^\s*\#' ${CURRENTLOCATION}/packages.list)
if [[ "$(uname -m)" == "x86_64" ]]; then
    LIST=$(echo -e "${LIST} \n $(grep -v '^$\|^\s*\#' ${CURRENTLOCATION}/packages64.list)")
fi

if [[ "$(uname -m)" == "i686" ]]; then
    LIST=$(echo -e "${LIST} \n $(grep -v '^$\|^\s*\#' ${CURRENTLOCATION}/packages32.list)")
fi

##################################################################
# Using Slackware
##################################################################
if [ -e "/etc/slackware-version" ]; then

    if [[ "$(whoami)" != "root" ]]; then
        echo "On Slackware, you need to be root in order to install packages"
        exit 0
    fi

    if [ -z "$(ls /var/log/packages/ | grep sbopkg)" ]; then
        echo "Please Install sbopkg and JDK Manually"
        exit 0
    fi

    if [[ "$(uname -m)" != "x86_64" ]] || [ -n "$(ls /var/log/packages/ | grep compat32)" ]; then
        LIST=$(echo -e "${LIST} \n $(grep -v '^$\|^\s*\#' ${CURRENTLOCATION}/packages32.list)")
    fi

    echo "Running Sbopkg"
    sbopkg -r

    if ! [ -e "/var/lib/sbopkg/queues/mysql-workbench.sqf" ]; then
        echo "Creating Queue files and dependencies"
        if [ -e "/usr/sbin/sqg" ]; then
            /usr/sbin/sqg -a
        else
            /usr/doc/sbopkg-$(sbopkg -v)/contrib/sqg -a
        fi
    fi

    for pkg in ${LIST}; do
        if [ -z $(ls /var/log/packages/ | egrep -m 1 -i "^${pkg}-") ]; then
            echo "Installing ${pkg}"
            if [ -e "/var/lib/sbopkg/queues/${pkg}.sqf" ]; then
                sbopkg -B -k -e continue -i ${pkg}.sqf
            else
                NOTINSTALLED+=("${pkg}")
            fi
        else
            echo "${pkg} already installed"
        fi
    done

    suffix=""
    for i in ${NOTINSTALLED[@]}; do
        echo "Going to install: ${i}"
        suffix="${suffix} -i ${i}"
    done

    sbopkg -k -e continue ${suffix}
fi
