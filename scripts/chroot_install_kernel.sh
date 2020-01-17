#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

#FORCED_KERNEL_VERSION=4.15.0-66-generic
#FORCED_KERNEL_SOURCE_VERSION=4.15.0.66.68

. ./scripts/functions

verlte()
{
  [ "$1" = "`echo -e \"$1\n$2\" | sort -V | head -n1`" ]
}

chrootdevel_unmount()
{
  sudo umount "$PWD/build.$GLOBAL_BASEARCH/chroot.devel"
}

chrootdevel_mount()
{
  sudo mount ./build.$GLOBAL_BASEARCH/chroot -t overlay -o "rw,relatime,lowerdir=./build.$GLOBAL_BASEARCH/chroot,upperdir=./build.$GLOBAL_BASEARCH/tmp/chroot.devel/upper,workdir=./build.$GLOBAL_BASEARCH/tmp/chroot.devel/work" ./build.$GLOBAL_BASEARCH/chroot.devel
}

if [ "$GLOBAL_CUSTOMKERNEL" == "1" ]
then 
  statusprint "Building own custom kernel with forensic patches applied.." &&
  statusprint "Setting up kernel build environment.." &&
  #[ -d "./build.$GLOBAL_BASEARCH/chroot.devel" ] && sudo rm -rf ./build.$GLOBAL_BASEARCH/chroot.devel/ ./build.$GLOBAL_BASEARCH/tmp/chroot.devel/
  mkdir ./build.$GLOBAL_BASEARCH/chroot.devel 2>&-;  mkdir -p ./build.$GLOBAL_BASEARCH/tmp/chroot.devel/{upper,work} 2>&-;
  chrootdevel_mount &&
  trap "chrootdevel_unmount" SIGINT SIGKILL SIGTERM &&

  statusprint "Creating development rootfs.." &&
  statusprint "Installing build tools and downloading kernel source.." &&
  chroot_exec build.$GLOBAL_BASEARCH/chroot.devel "export DEBIAN_FRONTEND=noninteractive
  KERNELPKG=\$(apt-cache show --no-all-versions linux-image-generic| grep '^Depends:' | sed 's/^Depends: \\([^, ]*\\)[, ].*/\\1/') &&
  KERNELPKG=\"linux-image-$FORCED_KERNEL_VERSION\" &&
  KERNELUNSIGNEDPKG=\${KERNELPKG/linux-image/linux-image-unsigned} &&
  apt-fast --yes install build-essential git bsdtar bc libssl-dev;
  mkdir -p /opt/kernel 2>&-; chmod o+w /opt/kernel; cd /opt/kernel;
  KERNELVER=\$(echo \"\$KERNELPKG\"| cut -d\"-\" -f1,3 | tee /opt/kernel/kernel.version ) &&
  apt-fast --yes build-dep \"\$KERNELUNSIGNEDPKG\"
  apt-get --yes source linux=$FORCED_KERNEL_SOURCE_VERSION
  KERNELDIR=\"/opt/kernel/\$KERNELVER\"
  cd \"\$KERNELDIR\" && [ ! -f debian_rules.cleaned ] && fakeroot debian/rules clean && touch debian_rules.cleaned" || ( chrootdevel_unmount; exit 1 )  &&

  statusprint "Patching kernel with write-blocker patch.." &&
  KERNELVER=$(cat ./build.$GLOBAL_BASEARCH/chroot.devel/opt/kernel/kernel.version) &&
  PATCHFILE=$( ls -1 ./resources/kernel/writeblocker/kernel/*.patch | sed 's,^.*/,,'| sort -r | while read t
  do
    PKVER=$(echo "$t" | cut -d'-' -f1,2)
    if verlte "$PKVER" "$KERNELVER"
    then
      echo "$t"
      break;
    fi
  done ) &&

  if [ -z "$PATCHFILE" ]
  then
    statusprint "No patch file selected. Aborting."
    exit 1
  else
    statusprint "Using the latest kernel patch file for current kernel: $PATCHFILE"
  fi &&
  sudo patch --forward --batch -b -d "./build.$GLOBAL_BASEARCH/chroot.devel/opt/kernel/$KERNELVER" -p1 < "./resources/kernel/writeblocker/kernel/$PATCHFILE" &&

  statusprint "Building kernel.." &&
  chroot_exec build.$GLOBAL_BASEARCH/chroot.devel "cd \"/opt/kernel/$KERNELVER\" && fakeroot debian/rules binary-headers binary-generic binary-perarch" &&

  statusprint "Installing kernel.." &&
  sudo cp -rv ./build.$GLOBAL_BASEARCH/chroot.devel/opt/kernel/linux-{image,modules}-* "./build.$GLOBAL_BASEARCH/chroot/tmp/" &&
  sudo umount ./build.$GLOBAL_BASEARCH/chroot.devel &&
  chroot_exec build.$GLOBAL_BASEARCH/chroot "export DEBIAN_FRONTEND=noninteractive
  apt-fast -y install linux-firmware
  dpkg -i /tmp/linux-{image,modules}*
  apt-fast --yes -f install
  rm /tmp/linux-image-*" &&

  statusprint "Copying write-blocker management tools.." &&
  sudo cp -v ./resources/kernel/writeblocker/userspace/tools/{wrtblk,wrtblk-ioerr,wrtblk-disable} ./build.$GLOBAL_BASEARCH/chroot/usr/sbin/ &&

  statusprint "Copying write-blocker udev rules.." &&
  sudo cp -v ./resources/kernel/writeblocker/userspace/udev/01-forensic-readonly.rules ./build.$GLOBAL_BASEARCH/chroot/lib/udev/rules.d/

else
  statusprint "Installing stock kernel version." &&
  if [ -n "$FORCED_KERNEL_VERSION" ]
  then
    chroot_exec build.$GLOBAL_BASEARCH/chroot "export DEBIAN_FRONTEND=noninteractive; apt-fast --yes install linux-image-$FORCED_KERNEL_VERSION linux-modules-$FORCED_KERNEL_VERSION linux-modules-extra-$FORCED_KERNEL_VERSION linux-firmware; apt-mark manual linux-modules-extra-$FORCED_KERNEL_VERSION"
  else
    chroot_exec build.$GLOBAL_BASEARCH/chroot "export DEBIAN_FRONTEND=noninteractive; apt-fast --yes install linux-image-generic linux-firmware"
  fi
fi


statusprint "Removing older kernels in ./build.$GLOBAL_BASEARCH/chroot.."
chroot_exec build.$GLOBAL_BASEARCH/chroot 'LATEST_KERNEL=`ls -1 /boot/vmlinuz-*-generic | sort | tail -n1 | cut -d"-" -f2-`
count=$(ls -1 /boot/vmlinuz-*-generic | wc -l)
if [ $count -gt 1 ]; then
  dpkg -l "linux-*" | sed '"'"'/^ii/!d; /'"'"'"${LATEST_KERNEL}"'"'"'/d; s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'"'"' | xargs sudo apt-get -y purge
fi'


exit 0;
