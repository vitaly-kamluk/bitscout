#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

CHROOTDIR="$PWD/build.$GLOBAL_BASEARCH/chroot"
export CHROOTDIR
nspawn_exec build.$GLOBAL_BASEARCH/chroot "/bin/bash -i" 1
