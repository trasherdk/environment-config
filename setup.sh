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
[ ! -e "${HOME}/ssh/config" ] && mkdir -p ${HOME}/ssh/ && touch ${HOME}/ssh/config

# Modify some /etc stuff
if [ -w "/etc/" ]; then

    if [ -f "/etc/inetd.conf" ]; then
        echo "Comment all inetd.conf services"
        sed -i 's/^#//g;s/^/#/g' /etc/inetd.conf
        echo ""
    fi

    if [ -z "$(egrep -i '^ ?All' /etc/hosts.deny)" ]; then
        echo "Closing hosts.deny"
        sed -i 's/^#//g;s/^/#/g' /etc/hosts.deny
        sed -i "\$i All: All"  /etc/hosts.deny
    fi

    LINES=( 'sshd:192.168.0.,192.168.1.,10.42.0.,127.0.0.1' 'httpd:127.0.0.1' )
    for l in ${LINES[@]}; do
        if [ -z $(grep -i ${l} /etc/hosts.allow) ]; then
            echo "Adding line ${l} to /etc/hosts.allow"
            sed -i "\$i ${l}"  /etc/hosts.allow
        fi
    done

fi

HOSTS=( 'adrastea' 'parsiphae' )
for h in ${HOSTS[@]}; do
    if [ -z $(grep -i -o ${h} ${HOME}/ssh/config) ]; then
        echo "Adding ssh host info from ${h} to ${HOME}/ssh/config"
        cat ${LOCATION}/config/ssh/${h} >> ${HOME}/ssh/config
        echo ""
    else
        echo "${h} already in ${HOME}/ssh/config"
    fi

    if [ -z "$(grep -i -o ${h} /etc/hosts)" ] && [ -w "/etc/hosts" ]; then
        echo "Adding ${h} to /etc/hosts"
        line=$(cat ${LOCATION}/config/hosts/${h})
        sed -i "\$i ${line}"  /etc/hosts
    fi
done

if ! [ -e "${HOME}/.bin/psysh" ]; then
    echo "Installing psysh"
    wget http://psysh.org/psysh -O ~/.bin/psysh
    chmod +x ~/.bin/psysh
    echo ""
fi

if ! [ -e "${HOME}/.bin/phpunit" ]; then
    echo "Installing phpunit"
    wget https://phar.phpunit.de/phpunit.phar -O ~/.bin/phpunit
    chmod +x ~/.bin/phpunit
    echo ""
fi

if ! [ -e "${HOME}/.bin/docker-compose" ]; then
    DCVERSION="1.8.0"
    echo "Installing docker-compose ${DCVERSION}"
    curl -L "https://github.com/docker/compose/releases/download/${DCVERSION}/docker-compose-$(uname -s)-$(uname -m)" > ${HOME}/.bin/docker-compose
    chmod +x ${HOME}/.bin/docker-compose
    echo ""
fi

bash "${LOCATION}/slackware/install.sh" "${LOCATION}"
bash "${LOCATION}/packages/install.sh" "${LOCATION}"
