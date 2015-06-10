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

        exists=0
        getent passwd $1 >/dev/null 2>&1 && exists=1
        if [ "${exists}" -eq 1 ] && [ -z "$(grep 'pratt' /etc/sudoers)" ]; then
            echo "Edditing Sudoers file"
            if [ -f "/etc/sudoers.tmp" ]; then
                echo "/etc/sudoers.tmp exists, cannot edit sudoers"
                exit 1
            fi

            touch /etc/sudoers.tmp
            echo "pratt ALL=NOPASSWD:/sbin/iwconfig,/sbin/iwlist,/sbin/ifconfig,/sbin/shutdown,/sbin/dhclient,/sbin/dhcpcd" >> /tmp/sudoers.new
            visudo -c -f /tmp/sudoers.new
            if [ "$?" -eq "0" ]; then
                cp /tmp/sudoers.new /etc/sudoers
            fi
            rm /etc/sudoers.tmp
            echo ""
        fi

        read -p "Do you want to install slackware packages? (y/n) " INSTALLPKGS
        if [[ "${INSTALLPKGS}" == "y" ]]; then
            bassh ${CURRENTLOCATION}/packages/install.sh ${ROOTLOCATION}
        fi
    fi

else
    echo "You are NOT using slackware"
fi
