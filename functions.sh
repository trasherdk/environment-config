#!/bin/bash
##################################################################
#  Common functions for the installation files
#  Michael Pratt <pratt@hablarmierda.net>
##################################################################
set -e

##################################################################
# Backup file/directory
##################################################################
function backupDirFile()
{
    local src=$(realpath "${1}")
    local dst=${2}

    if [ -e "${dst}" ]; then
        echo "Backing up ${dst}"
        mkdir -p ${HOME}/environment_backup/

        if [ -L "${dst}" ]; then
            echo "Symlink, no need to back it up"
        else
            if [ -f "${dst}" ]; then
                cp -rf "${dst}" "${HOME}/environment_backup/$(basename ${dst} | tr '.' '_')"
            else
                cp -rf "${dst}" "${HOME}/environment_backup/$(basename ${dst} | tr '.' '_')"
            fi
        fi

        rm -rf ${dst}
    fi
}

##################################################################
# Creates symlinks - Used in Installation files
##################################################################
function symlinkIt()
{
    local src=$(realpath "${1}")
    local dst=${2}

    backupDirFile "${src}" "${dst}"
    if [ -e "${src}" ]; then
        echo "Linking $(basename ${src})"
        ln -sf ${src} ${dst} || echo "Error Linking ${dst}"
    else
        echo "Could not find ${src}"
    fi
}


##################################################################
# Copies a file or directory
##################################################################
function copyIt()
{
    local src=$(realpath "${1}")
    local dst=${2}

    backupDirFile "${src}" "${dst}"
    if [ -e "${src}" ]; then
        echo "Copying $(basename ${src})"
        cp -rf ${src} ${dst} || echo "Error Copying ${dst}"
    else
        echo "Could not find ${src}"
    fi
}
