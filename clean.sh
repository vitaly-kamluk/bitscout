#!/bin/bash  
# This file is part of Bitscout remote digital forensics project.
# Copyright Kaspersky Lab. Contact: bitscout[at]kaspersky.com
# Bitscout is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version. 
# Bitscout is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with
# Bitscout. If not, see <http://www.gnu.org/licenses/>.

. ./scripts/functions
builddirs=( $(find $PWD -maxdepth 1 -type d | grep 'build\.' | sed 's/^.*\.\([^.]*\)$/\1/' ) )

statusprint "Unmounting filesystems from chroot environment.."
chroot_unmount_fs "./build.$GLOBAL_BASEARCH/chroot"

statusprint "Removing all temporary files for each architecture, except target image/iso file(s) and configuration.."
sudo rm -rf ./chroot
#sudo rm -rf ./chroot ./chroot.devel ./tmp ./image ./initrd ./recycle ./cache ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock

if [ ${#builddirs[@]} = 1 ]; then
    echo "Removing: ./build.${builddirs[0]} ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock ..."
    sudo rm -rf ./build.${builddirs[0]} ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock

elif [ ${#builddirs[@]} -gt 1 ]; then
    
    echo "There are more than 1 architectures found, please select which to be deleted based on the option number shown below."
    echo "0. ALL Architectures"
    for (( i=0;i<${#builddirs[@]}; i++ )); do
        echo $(($i+1))". ${builddirs[$i]}"
    done

    while [[ -z $choice  || ! $choice =~ ^-?[0-9]+$  ||  "$choice" -gt "${#builddirs[@]}" ||  "$choice" -lt "0" ]];
    do
        read -p "Please make your choice (Ctrl+C to abort): " choice
    done
    
    if [ "$choice" -ne "0" ]; then
        echo "Removing: ./build.${builddirs[$(($choice-1))]} ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock ..."
        sudo rm -rf ./build.${builddirs[$(($choice-1))]} ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock
    else
        echo "Removing ALL Architectures + ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock ..."
        sudo rm -rf  ./autotest.log ./automake.log ./bitscout.monitor.sock ./bitscout.serial.sock
        for (( i=0;i<${#builddirs[@]}; i++ )); do
            echo "Removing ./build.${builddirs[$(($i))]} ..."
            sudo rm -rf ./build.${builddirs[$(($i))]}
        done
    fi

else
    echo "Oops, nothing to clean.."
fi
