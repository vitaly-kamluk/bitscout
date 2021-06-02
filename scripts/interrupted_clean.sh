#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

PROJECTROOT=$PWD

( 
chroot_unmount_cache "$PWD/build.$GLOBAL_BASEARCH/chroot"
chroot_unmount_fs "$PWD/build.$GLOBAL_BASEARCH/chroot"
) 2>&1 > /dev/null
