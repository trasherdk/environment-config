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

# Modify some /etc stuff
if [ -w "/etc/" ]; then
    if [ -f "/etc/inetd.conf" ]; then
        echo "Comment all inetd.conf services"
        sed -i 's/^#//g;s/^/#/g' /etc/inetd.conf
        echo ""
    fi

    echo "Modifying hosts.allow/hosts.deny for more security"
    cp ${LOCATION}/hosts/hosts.allow /etc/hosts.allow
    cp ${LOCATION}/hosts/hosts.deny /etc/hosts.deny
    echo ""
fi

if ! [ -e "${HOME}/.bin/psysh" ]; then
    echo "Installing physh"
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

bash "${LOCATION}/slackware/install.sh" "${LOCATION}"
