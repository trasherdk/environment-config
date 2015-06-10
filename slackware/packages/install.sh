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

if [ -n "$(ls /var/log/packages/ | grep 'slackpkg+')" ]; then
    copyIt ${ROOTLOCATION}/slackware/config/slackpkgplus.conf /etc/slackpkg/slackpkgplus.conf

    echo "Using slackpkg/slackpkg+ to install alienbob stuff"
    slackpkg update
    slackpkg update gpg
    slackpkg install multilib chromium vlc ffmpeg wine libreoffice libreoffice-l10n-de libreoffice-l10n-es
else
    echo "Please Install slackpkg+"
fi

if [ -n "$(ls /var/log/packages/ | grep sbopkg)" ]; then
    echo "Running Sbopkg"
    sbopkg -r

    echo "Copying Queue files"
    mkdir -p /var/lib/sbopkg/queues/
    cp -r ${CURRENTLOCATION}/Queue/*sqf /var/lib/sbopkg/queues/

    sbopkg -k -B -e continue -i Core.sqf
    sbopkg -k -B -e continue -i Desktop.sqf
    sbopkg -k -B -e continue -i Development.sqf
    sbopkg -k -B -e continue -i Internet.sqf
    sbopkg -k -B -e continue -i Media.sqf
    sbopkg -k -B -e continue -i Office.sqf
    sbopkg -k -B -e continue -i Security.sqf
    sbopkg -k -B -e continue -i Games.sqf

    if [[ "$(uname -m)" != "x86_64" ]] || [ -n "$(ls /var/log/packages/ | grep compat32)" ]; then
        sbopkg -k -B -e continue -i 32Bit.sqf
    fi

    if [[ "$(uname -m)" == "x86_64" ]]; then
        sbopkg -e continue -k -i 64Bit.sqf
    fi

    echo "Cleaning /var/lib/sbopkg/queues/"
    rm -rf /var/lib/sbopkg/queues/*.sqf
else
    echo "Please Install sbopkg"
fi
