#!/bin/bash  
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
