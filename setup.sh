#!/bin/bash
##################################################################
#  This scripts bootstraps all the installation stuff
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
        echo "Modifying httpd.conf to allow userdir_module"
        sed -i 's:#Include /etc/httpd/extra/httpd-userdir.conf:Include /etc/httpd/extra/httpd-userdir.conf:' /etc/httpd/httpd.conf
        sed -i 's:#Include /etc/httpd/mod_php.conf:Include /etc/httpd/mod_php.conf:' /etc/httpd/httpd.conf

        echo "Enabling mod_rewrite and userdir_module"
        if [ -f "/usr/lib64/httpd/modules/mod_userdir.so" ]; then
            sed -i 's:#LoadModule userdir_module lib64/httpd/modules/mod_userdir.so:LoadModule userdir_module lib64/httpd/modules/mod_userdir.so:' /etc/httpd/httpd.conf
            sed -i 's:#LoadModule rewrite_module lib64/httpd/modules/mod_rewrite.so:LoadModule rewrite_module lib64/httpd/modules/mod_rewrite.so:' /etc/httpd/httpd.conf
        elif [ -f "/usr/lib/httpd/modules/mod_userdir.so" ]; then
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

    if [ -z "$(grep '9c20bd82-1f3d-416e-b524-380172cd6959' /etc/fstab)" ]; then
        echo "Writing mount datapoints for my M3 External Drive into fstab"
        mkdir -p /mnt/{share,storage,backup}
        echo "# SAMSUNG M3 External Drive" >> /etc/fstab
        echo "/dev/disk/by-uuid/108639C48639AB5C                      /mnt/share   ntfs   defaults,user,rw,umask=000,exec,comment=x-gvfs-show  0   0" >> /etc/fstab
        echo "/dev/disk/by-uuid/9c20bd82-1f3d-416e-b524-380172cd6959  /mnt/storage ext4   defaults,user,exec,comment=x-gvfs-show            0   0" >> /etc/fstab
        echo "/dev/disk/by-uuid/4baf3ce6-d77e-4da9-903c-fec952096f70  /mnt/backup  ext4   defaults,user,exec,comment=x-gvfs-show            0   0" >> /etc/fstab
        echo ""
    fi
fi

bash "${LOCATION}/slackware/install.sh" "${LOCATION}"
