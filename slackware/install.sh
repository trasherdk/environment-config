#!/bin/bash
##################################################################
#  Install slackware stuff
#  Michael Pratt <pratt@hablarmierda.net>
##################################################################
set -e
ROOTLOCATION=${1}
CURRENTLOCATION="${ROOTLOCATION}/slackware"

# Source functions
source "${ROOTLOCATION}/functions.sh"

##################################################################
# Check for slackware
##################################################################
if [ -e "/etc/slackware-version" ]; then

    echo "Slackware Detected"
    echo "Linking Slackware Stuff"
    symlinkIt ${ROOTLOCATION}/slackware ~/.slackware
    symlinkIt ${ROOTLOCATION}/slackware/slackware.sh ~/.slackware.sh
    echo ""

    if [ -w "/etc/rc.d/" ]; then
        echo "Copying scripts to /etc/rc.d/"
        copyIt ${CURRENTLOCATION}/config/rc.firewall /etc/rc.d/rc.firewall
        copyIt ${CURRENTLOCATION}/config/rc.local /etc/rc.d/rc.local
        copyIt ${CURRENTLOCATION}/config/rc.local_shutdown /etc/rc.d/rc.local_shutdown
        echo ""

        if [ -z "$(grep 'startup.mp4' /etc/rc.d/rc.S)" ]; then
            echo "Applying Bootsplash patch"
            cd /etc/rc.d/
            cp ${CURRENTLOCATION}/config/bootsplash.patch /etc/rc.d/
            patch -p1 -N < bootsplash.patch
            rm -rf /etc/rc.d/bootsplash.patch
            echo ""
        fi

        if [ ! -e "/boot/video/startup.mp4" ] && [ -e "${CURRENTLOCATION}/config/video/bwtbm-startup.mp4" ]; then
            mkdir -p /boot/video/
            echo "Copy startup video to /boot/video/startup.mp4"
            cp -r ${CURRENTLOCATION}/config/video/bwtbm-startup.mp4 /boot/video/startup.mp4
            echo ""
        fi
    fi

    if [[ $(whoami) == "root" ]]; then

        if ! grep ^vboxusers: /etc/group 2>&1 > /dev/null; then
            echo "Creating vboxusers group!"
            groupadd -g 215 vboxusers
            echo ""
        fi

        if ! grep ^docker: /etc/group 2>&1 > /dev/null; then
            echo "Creating docker group!"
            groupadd -r -g 281 docker
            echo ""
        fi

        read -p "Do you want to install slackware packages? (y/n) " INSTALLPKGS
        if [[ "${INSTALLPKGS}" == "y" ]]; then
            bash ${CURRENTLOCATION}/packages/install.sh ${ROOTLOCATION}
        fi
    fi

else
    echo "You are NOT using slackware"
fi
