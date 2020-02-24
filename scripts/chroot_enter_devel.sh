#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

chrootdevel_unmount()
{
  sudo umount "$PWD/build.$GLOBAL_BASEARCH/chroot.devel"
}

chrootdevel_mount()
{
  sudo mount ./build.$GLOBAL_BASEARCH/chroot -t overlay -o "rw,relatime,lowerdir=./build.$GLOBAL_BASEARCH/chroot,upperdir=./build.$GLOBAL_BASEARCH/tmp/chroot.devel/upper,workdir=./build.$GLOBAL_BASEARCH/tmp/chroot.devel/work" ./build.$GLOBAL_BASEARCH/chroot.devel
}

chrootdevel_mount
chroot_exec build.$GLOBAL_BASEARCH/chroot.devel "/bin/bash -i"
chrootdevel_unmount
