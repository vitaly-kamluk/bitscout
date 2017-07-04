#!/bin/bash  
#This file is part of Bitscout 2.0 project.
#Bitscout is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#Bitscout is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Bitscout. If not, see <http://www.gnu.org/licenses/>.

scripts/welcome.sh &&
scripts/chroot_download.sh &&
scripts/chroot_postdownload_setup.sh &&
scripts/chroot_install_base.sh &&
scripts/chroot_install_forensics.sh &&
scripts/chroot_install_remoteaccess.sh &&
scripts/chroot_create_user.sh &&
scripts/chroot_create_container.sh &&
scripts/chroot_configure.sh &&
scripts/chroot_configure_openvpn.sh &&
scripts/chroot_configure_ssh.sh &&
scripts/chroot_configure_irc.sh &&
scripts/chroot_add_managementtool.sh &&
scripts/image_prepare.sh &&
scripts/initrd_configure.sh &&
scripts/image_prebuild_cleanup.sh &&
scripts/image_build.sh &&
scripts/export_generate.sh
