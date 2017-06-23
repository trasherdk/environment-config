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

HOSTS=( 'adrastea' 'pasiphae' )
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
done

if [ -w "/etc/udev/rules.d/" ]; then
    echo "Adding Touchpad rules, when adding"
    cat ${LOCATION}/config/udev/01-touchpad.rules > /etc/udev/rules.d/01-touchpad.rules
    echo ""
fi

if [ -w "/etc/X11/xorg.conf.d/" ]; then
    echo "Adding Touchpad configuration options to X11"
    cat ${LOCATION}/config/X11/60-synaptics.conf > /etc/X11/xorg.conf.d/60-synaptics.conf
    echo ""
fi

if [ -w "/etc/sudoers.d/" ]; then
    echo "Adding pratt sudoers config"
    cat ${LOCATION}/config/sudo/50-pratt.conf > /etc/sudoers.d/50-pratt.conf
    echo ""
fi

if [ -w "/usr/share/apps/kdm/sessions/" ]; then
    echo "Adding i3 (with dbus) item to KDM"
    cat ${LOCATION}/config/i3/i3-dbus.desktop > /usr/share/apps/kdm/sessions/i3-dbus.desktop
fi

if ! [ -e "${HOME}/.bin/psysh" ]; then
    echo "Installing psysh"
    wget http://psysh.org/psysh -O ~/.bin/psysh
    chmod +x ~/.bin/psysh
    echo ""
fi

if ! [ -e "${HOME}/.bin/phpunit" ]; then
    echo "Installing phpunit"
    #wget https://phar.phpunit.de/phpunit-6.0.phar -O ~/.bin/phpunit
    wget https://phar.phpunit.de/phpunit-5.7.phar -O ~/.bin/phpunit
    chmod +x ~/.bin/phpunit
    echo ""
fi

if ! [ -e "${HOME}/.bin/phploc" ]; then
    echo "Installing phploc"
    curl -L "https://phar.phpunit.de/phploc.phar" > ${HOME}/.bin/phploc
    chmod +x ${HOME}/.bin/phploc
    echo ""
fi

if ! [ -e "${HOME}/.bin/docker-compose" ]; then
    DCVERSION="1.8.0"
    echo "Installing docker-compose ${DCVERSION}"
    curl -L "https://github.com/docker/compose/releases/download/${DCVERSION}/docker-compose-$(uname -s)-$(uname -m)" > ${HOME}/.bin/docker-compose
    chmod +x ${HOME}/.bin/docker-compose
    echo ""
fi

if ! [ -e "${HOME}/.bin/gdrive" ]; then
    echo "Installing gdrive"
    curl -L "https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download" > ${HOME}/.bin/gdrive
    chmod +x ${HOME}/.bin/gdrive
    echo ""
fi

bash "${LOCATION}/slackware/install.sh" "${LOCATION}"
bash "${LOCATION}/packages/install.sh" "${LOCATION}"
