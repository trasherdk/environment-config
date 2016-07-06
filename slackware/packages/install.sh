#!/bin/bash
###############################################
#  Install Slackware Packages
#  Michael Pratt <pratt@hablarmierda.net>
###############################################
ROOTLOCATION=${1}
CURRENTLOCATION="${ROOTLOCATION}/slackware/packages"
VERSION=$(cat /etc/slackware-version | egrep -o '[0-9\.]+')

# Source functions
source "${ROOTLOCATION}/functions.sh"

##################################################################
# Check for slackware
##################################################################
if ! [ -e "/etc/slackware-version" ]; then
    echo "Not using Slackware"
    exit 0
fi

if [[ "$(whoami)" != "root" ]]; then
    echo "You are not root!"
    exit 0
fi

echo "Building local SlackBuilds"
if [ -z "$(ls /var/log/packages/ | grep areao)" ]; then
    echo "Building Areao Icon theme"
    cd ${CURRENTLOCATION}/Slackbuilds/areao-icon-theme/
    sh areao-icon-theme.SlackBuild
    upgradepkg --install-new /tmp/*.t?z
else
    echo "Skipping Areao Icon Theme"
fi

if [ -z "$(ls /var/log/packages/ | grep ridance)" ]; then
    echo "Building Ambience/Ridance Icon theme"
    cd ${CURRENTLOCATION}/Slackbuilds/ambiance-ridance-flat-colors-theme/
    sh ambiance-ridance-flat-colors-theme.SlackBuild
    upgradepkg --install-new /tmp/*.t?z
else
    echo "Skipping Amnbience/Ridance Icon Theme"
fi

if [ -n "$(ls /var/log/packages/ | grep 'slackpkg+')" ]; then
    echo "Using slackpkg/slackpkg+ to install alienbob stuff"
    #slackpkg update
    #slackpkg update gpg

    alienpkgs="multilib chromium vlc ffmpeg wine libreoffice libreoffice-l10n-de libreoffice-l10n-es"
    for p in ${alienpkgs}; do
        slackpkg install ${p}
    done
else
    echo "Please Install slackpkg+"
fi

if [ -n "$(ls /var/log/packages/ | grep sbopkg)" ]; then
    echo "Getting sbopkg Version"
    SBOVER=$(sbopkg -v)

    echo "Running Sbopkg"
    sbopkg -r

    echo "Creating Queue files and dependencies"
    if [ -e "/usr/doc/sbopkg-$SBOVER/contrib/sqg" ] || [ -e "/usr/sbin/sqg" ]; then

        if ! [ -e "/var/lib/sbopkg/queues/mysql-workbench.sqf" ]; then
            /usr/doc/sbopkg-$SBOVER/contrib/sqg -a || /usr/sbin/sqg -a
        else
            echo "Queue files already generated"
        fi

        for pkg in $(grep -v '^$\|^\s*\#' ${ROOTLOCATION}/slackware/packages/packages.list); do
            if [ -e "/var/lib/sbopkg/queues/${pkg}.sqf" ]; then
                sbopkg -B -k -e continue -i ${pkg}.sqf
            fi
        done

        if [[ "$(uname -m)" != "x86_64" ]] || [ -n "$(ls /var/log/packages/ | grep compat32)" ]; then
            sbopkg -B -k -e continue -i skype
            sbopkg -B -k -e continue -i skype-call-recorder
            sbopkg -B -k -e continue -i mplayer-codecs32
        fi

        if [[ "$(uname -m)" == "x86_64" ]]; then
            sbopkg -B -k -e continue -i mplayer-codecs64
        fi

    else
        echo "Could not generate queue files"
    fi

else
    echo "Please Install sbopkg and JDK"
fi
