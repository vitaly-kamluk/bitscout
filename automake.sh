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
SECONDS=0
scripts/welcome.sh &&
scripts/submodules_fetch.sh &&

#prepare rootfs directory:
scripts/chroot_download.sh &&
scripts/chroot_postdownload_setup.sh &&
scripts/chroot_install_base.sh &&
scripts/chroot_install_kernel.sh &&
scripts/chroot_install_forensics.sh &&
#scripts/chroot_install_forensics_extra.sh && #several issues need to be resolved
scripts/chroot_install_remoteaccess.sh &&
scripts/chroot_customize.sh &&


#configure target system:
scripts/chroot_create_user.sh &&
scripts/chroot_create_container.sh &&
scripts/chroot_configure.sh &&
scripts/chroot_configure_vpn.sh &&
scripts/chroot_configure_ssh.sh &&
scripts/chroot_configure_irc.sh &&
scripts/chroot_configure_syslog.sh &&

#adding management tool(s):
scripts/chroot_add_managementtool.sh &&
scripts/chroot_internet_indicator.sh &&

#prepare ISO files:
scripts/image_prepare.sh &&

#reduce size of the rootfs:
scripts/image_prebuild_cleanup.sh &&

#apply initrd/casper fixes: 
scripts/initrd_unpack.sh &&
scripts/initrd_findlivefs_fix.sh &&
#scripts/initrd_integritycheck_fix.sh &&
scripts/initrd_writeblocker.sh &&
scripts/initrd_doublesword.sh &&
scripts/initrd_pack.sh &&

#buld the target iso or disk image
scripts/image_build.sh &&

#prepare exportable configs/certs/keys:
scripts/export_generate.sh 

duration=$SECONDS
echo "Process finished. Time taken: $(($duration / 60)) min. $(($duration % 60)) sec."
) 2>&1 | stdbuf -i0 -o0 -e0 tee  ./automake.log

#Final cleanup in case of interrupted builds
scripts/interrupted_clean.sh

