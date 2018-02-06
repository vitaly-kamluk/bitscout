#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

verlte()
{
  [ "$1" = "`echo -e \"$1\n$2\" | sort -V | head -n1`" ]
}

chrootdevel_unmount()
{
  sudo umount "$PWD/chroot.devel"
}

chrootdevel_mount()
{
  sudo mount ./chroot -t overlay -o "rw,relatime,lowerdir=./chroot,upperdir=./tmp/chroot.devel/upper,workdir=./tmp/chroot.devel/work" ./chroot.devel
}

if [ "$GLOBAL_CUSTOMKERNEL" == "1" ]
then 
  statusprint "Building own custom kernel with forensic patches applied.."
  statusprint "Setting up kernel build environment.."
  #[ -d "./chroot.devel" ] && sudo rm -rf ./chroot.devel/ ./tmp/chroot.devel/
  mkdir ./chroot.devel 2>&-; mkdir -p ./tmp/chroot.devel/{upper,work} 2>&-
  chrootdevel_mount
  trap "chrootdevel_unmount" SIGINT SIGKILL SIGTERM

  statusprint "Creating development rootfs.."  
  statusprint "Installing build tools and downloading kernel source.."
  chroot_exec chroot.devel "export DEBIAN_FRONTEND=noninteractive
  KERNELPKG=\$(apt-cache show --no-all-versions linux-image-generic| grep '^Depends:' | sed 's/^Depends: \\([^, ]*\\)[, ].*/\\1/')
  apt-fast --yes install build-essential git bsdtar &&
  mkdir /opt/kernel 2>&-; chmod o+w /opt/kernel && cd /opt/kernel;
  mv -v /bin/tar /bin/tar.distrib && ln -fs /usr/bin/bsdtar /bin/tar &&
  apt-get --yes source \"\$KERNELPKG\" &&
  mv -v /bin/tar.distrib /bin/tar && 
  apt-fast --yes build-dep \"\$KERNELPKG\"
  KERNELVER=\$(echo \"\$KERNELPKG\"| cut -d\"-\" -f1,3 | tee /opt/kernel/kernel.version )
  KERNELDIR=\"/opt/kernel/\$KERNELVER\"
  cd \"\$KERNELDIR\" && [ ! -f debian_rules.cleaned ] && fakeroot debian/rules clean && touch debian_rules.cleaned"

  statusprint "Patching kernel with write-blocker patch.."
  KERNELVER=$(cat ./chroot.devel/opt/kernel/kernel.version)
  PATCHFILE=$( ls -1 ./resources/kernel/writeblocker/kernel/*.patch | sed 's,^.*/,,'| sort -r | while read t
  do
    PKVER=$(echo "$t" | cut -d'-' -f1,2)
    if verlte "$PKVER" "$KERNELVER"
    then
      echo "$t"
      break;
    fi
  done )

  if [ -z "$PATCHFILE" ]
  then
    statusprint "No patch file selected. Aborting."
    exit 1
  fi
  sudo patch --forward --batch -b -d "./chroot.devel/opt/kernel/$KERNELVER" -p1 < "./resources/kernel/writeblocker/kernel/$PATCHFILE"

  statusprint "Building kernel.."
  chroot_exec chroot.devel "cd \"/opt/kernel/$KERNELVER\" && fakeroot debian/rules binary-headers binary-generic binary-perarch"

  statusprint "Installing kernel.."
  sudo cp -rv ./chroot.devel/opt/kernel/linux-image-* "./chroot/tmp/"
  sudo umount ./chroot.devel
  chroot_exec chroot "export DEBIAN_FRONTEND=noninteractive
  apt-fast -y install linux-firmware
  dpkg -i /tmp/linux-image-*
  apt-fast --yes -f install
  rm /tmp/linux-image-*"

  statusprint "Copying write-blocker management tools.."
  sudo cp -v ./resources/kernel/writeblocker/userspace/tools/{wrtblk,wrtblk-ioerr,wrtblk-disable} ./chroot/usr/sbin/

  statusprint "Copying write-blocker udev rules.."
  sudo cp -v ./resources/kernel/writeblocker/userspace/udev/01-forensic-readonly.rules ./chroot/lib/udev/rules.d/

else
  statusprint "Installing stock kernel version."
  chroot_exec chroot "export DEBIAN_FRONTEND=noninteractive; apt-fast --yes install linux-image-generic"
fi


statusprint "Removing older kernels in chroot.."
chroot_exec chroot 'LATEST_KERNEL=`ls -1 /boot/vmlinuz-*-generic | sort | tail -n1 | cut -d"-" -f2-`
count=$(ls -1 /boot/vmlinuz-*-generic | wc -l)
if [ $count -gt 1 ]; then
  dpkg -l "linux-*" | sed '"'"'/^ii/!d; /'"'"'"${LATEST_KERNEL}"'"'"'/d; s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'"'"' | xargs sudo apt-get -y purge
fi'


exit 0;
