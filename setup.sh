#!/bin/bash
##################################################################
#  This scripts bootstraps all the installation routine
#  Michael Pratt <pratt@hablarmierda.net>
##################################################################
set -e
LOCATION=$(realpath $(dirname $0))

##################################################################
# The logic
##################################################################
# Create .bin directory
mkdir -p ~/.bin/
[ ! -e "${HOME}/.ssh/config" ] && mkdir -p ${HOME}/.ssh/ && touch ${HOME}/.ssh/config

if [ -w "/etc/inetd.conf" ]; then
    echo "Comment all inetd.conf services"
    sed -i 's/^#//g;s/^/#/g' /etc/inetd.conf
    echo ""
fi

if [ -w "/etc/fstab" ] &&  [ -z "$(grep -i '64e868cc-05f2-4096-a321-d5af6b36eb8b' /etc/fstab)" ]; then
    [ -w "/mnt" ] && mkdir -p /mnt/storage && mkdir -p /mnt/share && mkdir -p /mnt/windows
    echo "Adding External Mount Points to /etc/fstab"
    cat ${LOCATION}/config/fstab/fstab >> /etc/fstab
    echo ""
fi

if [ -z "$(egrep -i '^ ?All' /etc/hosts.deny)" ] && [ -w "/etc/hosts.deny" ]; then
    echo "Closing hosts.deny"
    sed -i 's/^#//g;s/^/#/g' /etc/hosts.deny
    sed -i "\$i All: All"  /etc/hosts.deny
fi

LINES=( 'sshd:192.168.0.,192.168.1.,10.42.0.,127.0.0.1' 'httpd:127.0.0.1' )
for l in ${LINES[@]}; do
    if [ -z $(grep -i ${l} /etc/hosts.allow) ] && [ -w "/etc/hosts.allow" ]; then
        echo "Adding line ${l} to /etc/hosts.allow"
        sed -i "\$i ${l}"  /etc/hosts.allow
    fi
done

if [ -z "$(grep -i -o 'ServerAliveInterval 60' ${HOME}/.ssh/config)" ]; then
    echo "Adding General ssh config into ${HOME}/.ssh/config"
    cat ${LOCATION}/config/ssh/main >> ${HOME}/.ssh/config
fi

HOSTS=( 'adrastea' 'pasiphae' 'amalthea' )
for h in ${HOSTS[@]}; do
    if [ -z $(grep -i -o ${h} ${HOME}/.ssh/config) ]; then
        echo "Adding ssh host info from ${h} to ${HOME}/.ssh/config"
        cat ${LOCATION}/config/ssh/${h} >> ${HOME}/.ssh/config
    else
        echo "${h} already in ${HOME}/.ssh/config"
    fi

    if [ -z "$(grep -i -o ${h} /etc/hosts)" ] && [ -w "/etc/hosts" ]; then
        echo "Adding ${h} to /etc/hosts"
        line=$(cat ${LOCATION}/config/hosts/${h})
        sed -i "\$i ${line}"  /etc/hosts
    fi

    if [ -w "/etc/NetworkManager/system-connections/" ] && [ -n "$(grep -i -o ${h} /etc/HOSTNAME)" ]; then
        echo "Creating network configuration for ${h}"

        if [ -e "${LOCATION}/config/nm/${h}-central-city" ]; then
            cat ${LOCATION}/config/nm/${h}-central-city > "/etc/NetworkManager/system-connections/central city"
            chmod root:root "/etc/NetworkManager/system-connections/central city"
            chmod 600 "/etc/NetworkManager/system-connections/central city"
        fi

        if [ -e "${LOCATION}/config/nm/${h}-wired-local" ]; then
            cat ${LOCATION}/config/nm/${h}-wired-local > "/etc/NetworkManager/system-connections/wired-local"
            chown root:root "/etc/NetworkManager/system-connections/wired-local"
            chmod 600 "/etc/NetworkManager/system-connections/wired-local"
        fi
    fi

    # Pasiphae Settings only
    if [[ "${h}" == "pasiphae" ]]; then
        if [ -w "/etc/udev/rules.d/" ]; then
            echo "Adding Touchpad udev rules (disable when mouse is connected)"
            cat ${LOCATION}/config/udev/01-touchpad.rules > /etc/udev/rules.d/01-touchpad.rules
            echo ""
        fi

        if [ -w "/etc/X11/xorg.conf.d/" ]; then
            echo "Adding Touchpad configuration options to X11"
            cat ${LOCATION}/config/X11/60-synaptics.conf > /etc/X11/xorg.conf.d/60-synaptics.conf
            echo ""
        fi
    fi

    # Amalthea Settings only
    if [[ "${h}" == "amalthea" ]]; then
        if [ -w "/etc/X11/xorg.conf" ]; then
            if [ -z $(grep -o 'ACER' '/etc/X11/xorg.conf') ]; then
                echo "Adding dual monitor support to amalthea Xorg.conf"
                cat ${LOCATION}/config/X11/xorg.amalthea.conf > /etc/X11/xorg.conf
                echo ""
            fi
        fi

        if [ -w "/etc/kde/kdm/Xsetup" ]; then
            if [ -z "$(grep -o 'xrandr' '/etc/kde/kdm/Xsetup')" ]; then
                echo "Adding dual monitor initialization scripts to kdm"
                cat ${LOCATION}/slackware/bin/dual-monitors | egrep -v '^#' >> /etc/kde/kdm/Xsetup
                echo ""
            fi
        fi
    fi
done

if [ -w "/etc/sudoers.d/" ]; then
    echo "Adding pratt sudoers config"
    cat ${LOCATION}/config/sudo/50-pratt.conf > /etc/sudoers.d/50-pratt
    chmod 0440 /etc/sudoers.d/50-pratt
    echo ""
fi

if [ -w "/usr/share/apps/kdm/sessions/" ]; then
    echo "Adding i3 (with dbus) item to KDM"
    cat ${LOCATION}/config/i3/i3-dbus.desktop > /usr/share/apps/kdm/sessions/i3-dbus.desktop
fi

if [ -w "/etc/" ]; then

    if ! [ -d "/etc/chromium/" ]; then
        mkdir -p /etc/chromium/
    fi

    echo "Adding Chromium customization"
    cat ${LOCATION}/config/chromium/90-kwallet.conf > /etc/chromium/90-kwallet.conf
    chmod 644 /etc/chromium/90-kwallet.conf
    echo ""
fi

if ! [ -e "${HOME}/.bin/psysh" ]; then
    echo "Installing psysh"
    wget http://psysh.org/psysh -O ~/.bin/psysh
    chmod +x ~/.bin/psysh
    echo ""
fi

if ! [ -e "${HOME}/.bin/phpunit" ]; then
    if [ "$(php -v | egrep -o 'PHP ([0-9])' | awk '{print $2}')" -eq "5" ]; then
        PVER="5.7"
    else
        PVER="6.0"
    fi

    echo "Installing phpunit ${PVER}"
    wget https://phar.phpunit.de/phpunit-${PVER}.phar -O ~/.bin/phpunit
    chmod +x ~/.bin/phpunit
    echo ""
fi

if ! [ -e "${HOME}/.bin/phploc" ]; then
    echo "Installing phploc"
    curl -L "https://phar.phpunit.de/phploc.phar" > ${HOME}/.bin/phploc
    chmod +x ${HOME}/.bin/phploc
    echo ""
fi

if ! [ -e "${HOME}/.bin/gdrive" ]; then
    echo "Installing gdrive"
    curl -L "https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download" > ${HOME}/.bin/gdrive
    chmod +x ${HOME}/.bin/gdrive
    echo ""
fi

if ! [ -e "${HOME}/.bin/googler" ]; then
    echo "Installing googler"
    curl -L "https://raw.githubusercontent.com/jarun/googler/v3.1/googler" > ${HOME}/.bin/googler
    chmod +x ${HOME}/.bin/googler
    echo ""
fi

if ! [ -e "${HOME}/.bin/phpmd" ]; then
    echo "Installing PHP Mess Detector"
    curl -L "http://static.phpmd.org/php/latest/phpmd.phar" > ${HOME}/.bin/phpmd
    chmod +x ${HOME}/.bin/phpmd
    echo ""
fi

if ! [ -e "${HOME}/.bin/phpcs" ] || ! [ -e "${HOME}/.bin/phpcbf" ]; then
    echo "Installing PHP Code Sniffer"
    curl -L "https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar" > ${HOME}/.bin/phpcs
    curl -L "https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar" > ${HOME}/.bin/phpcbf
    chmod +x ${HOME}/.bin/phpcs
    chmod +x ${HOME}/.bin/phpcbf
    echo ""
fi

bash "${LOCATION}/slackware/install.sh" "${LOCATION}"
bash "${LOCATION}/packages/install.sh" "${LOCATION}"
