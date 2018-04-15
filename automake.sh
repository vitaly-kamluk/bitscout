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

#welcome and initial settings:
( 
scripts/welcome.sh &&
scripts/submodules_fetch.sh &&

#prepare rootfs directory:
scripts/chroot_download.sh &&
scripts/chroot_postdownload_setup.sh &&
scripts/chroot_install_base.sh &&
scripts/chroot_install_kernel.sh &&
scripts/chroot_install_forensics.sh &&
scripts/chroot_install_remoteaccess.sh &&
scripts/chroot_install_userchoice.sh &&

#configure target system:
scripts/chroot_create_user.sh &&
scripts/chroot_create_container.sh &&
scripts/chroot_configure.sh &&
scripts/chroot_configure_openvpn.sh &&
scripts/chroot_configure_ssh.sh &&
scripts/chroot_configure_irc.sh &&

#customize with own tools:
scripts/chroot_add_managementtool.sh &&

#prepare ISO files:
scripts/image_prepare.sh &&

#apply initrd/casper fixes:
scripts/initrd_unpack.sh &&
scripts/casper_findlivefs_fix.sh &&
scripts/casper_integritycheck_fix.sh &&
scripts/casper_writeblocker.sh &&
scripts/initrd_pack.sh &&

#reduce size of rootfs and build ISO:
scripts/image_prebuild_cleanup.sh &&
scripts/image_build.sh &&

#prepare exportable configs/certs/keys:
scripts/export_generate.sh 
) 2>&1 | tee  ./automake.log

