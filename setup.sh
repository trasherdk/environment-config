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

    if [ -e "/etc/httpd/httpd.conf" ]; then

        if [ -f "/etc/httpd/extra/httpd-userdir.conf" ]; then
            echo "Modifying httpd.conf to allow userdir_module"
            sed -i 's:#Include /etc/httpd/extra/httpd-userdir.conf:Include /etc/httpd/extra/httpd-userdir.conf:' /etc/httpd/httpd.conf
            sed -i 's:#Include /etc/httpd/mod_php.conf:Include /etc/httpd/mod_php.conf:' /etc/httpd/httpd.conf
        fi

        if [ -f "/usr/lib64/httpd/modules/mod_userdir.so" ]; then
            echo "Enabling mod_rewrite and userdir_module (64Bit)"
            sed -i 's:#LoadModule userdir_module lib64/httpd/modules/mod_userdir.so:LoadModule userdir_module lib64/httpd/modules/mod_userdir.so:' /etc/httpd/httpd.conf
            sed -i 's:#LoadModule rewrite_module lib64/httpd/modules/mod_rewrite.so:LoadModule rewrite_module lib64/httpd/modules/mod_rewrite.so:' /etc/httpd/httpd.conf
        elif [ -f "/usr/lib/httpd/modules/mod_userdir.so" ]; then
            echo "Enabling mod_rewrite and userdir_module (32Bit)"
            sed -i 's:#LoadModule userdir_module lib/httpd/modules/mod_userdir.so:LoadModule userdir_module lib/httpd/modules/mod_userdir.so:' /etc/httpd/httpd.conf
            sed -i 's:#LoadModule rewrite_module lib/httpd/modules/mod_rewrite.so:LoadModule rewrite_module lib/httpd/modules/mod_rewrite.so:' /etc/httpd/httpd.conf
        fi

        if [ -z "$(grep 'index.php' /etc/httpd/httpd.conf)" ]; then
            echo "Enabling index.php in the DirectoryIndex directive"
            sed -i 's:DirectoryIndex index.html:DirectoryIndex index.html index.php:' /etc/httpd/httpd.conf
        fi

        if [ -z "$(grep 'ServerSignature' /etc/httpd/httpd.conf)" ]; then
            echo "Disable ServerSignature and ServerTokens"
            echo -e "ServerSignature Off" >> /etc/httpd/httpd.conf
            echo -e "ServerTokens Prod" >> /etc/httpd/httpd.conf
        fi

        echo ""
    fi
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
