#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Checking base requirements.."
if [ -z "$(which dpkg-query)" ]
then
 echo "dpkg is required to continue. Please install manually."
 exit 2
fi

run_debootstrap_supervised_fast()
{
  statusprint "Downloading $BASERELEASE:$BASEARCHITECTURE.."

  BASEDIR="$PWD"
  statusprint "Building debootstrap cache dir.."
  DEBDIR="debootstrap.cache/dists/$BASERELEASE/main/binary-$BASEARCHITECTURE"
  mkdir -p "$DEBDIR"

  statusprint "Fetching list of deb files for local repository.."
  DEBS=$(sudo debootstrap --include=aria2,libc-ares2,libssh2-1,libxml2,ca-certificates,zlib1g,localepurge --print-debs --foreign --arch=$BASEARCHITECTURE $BASERELEASE chroot)
  install_required_package aria2
  APTFAST="scripts/apt-fast/apt-fast"

  statusprint "Downloading files to debootstrap cache dir.."
  ( cd "$DEBDIR" && "$BASEDIR/$APTFAST" download $DEBS )

  statusprint "Scanning downloaded packages.."
  ( cd "./debootstrap.cache" && dpkg-scanpackages . /dev/null > "dists/$BASERELEASE/main/binary-$BASEARCHITECTURE/Packages" 2>/dev/null )
  sed -i 's/^Priority: optional.*/Priority: important/g' "$DEBDIR/Packages"

  PKGS_SIZE=$(stat -c %s ./debootstrap.cache/dists/$BASERELEASE/main/binary-$BASEARCHITECTURE/Packages)
  statusprint "Building mirror requirements.."

  echo "Origin: Ubuntu
Label: Ubuntu
Suite: $BASERELEASE
Version: 16.04
Codename: $BASERELEASE
Date: Thu, 21 Apr 2016 23:23:46 UTC
Architectures: $BASEARCHITECTURE
Components: main restricted universe multiverse
Description: Ubuntu Xenial 16.04

MD5Sum:
$(md5sum $DEBDIR/Packages | cut -d' ' -f1) $PKGS_SIZE main/binary-$BASEARCHITECTURE/Packages
SHA256:
$(sha256sum $DEBDIR/Packages | cut -d' ' -f1) $PKGS_SIZE main/binary-$BASEARCHITECTURE/Packages" > "./debootstrap.cache/dists/$BASERELEASE/Release"

  sudo debootstrap --no-check-gpg --foreign --arch=$BASEARCHITECTURE $BASERELEASE chroot "file:///$BASEDIR/debootstrap.cache"

  statusprint "Fixing keyboard-configuration GDM compatibility bug (divert kbd_mode).."
  TARGETDEB="./chroot$(grep "^kbd " chroot/debootstrap/debpaths | cut -d' ' -f2)"
  if [ "$TARGETDEB" == "./chroot" ]
  then
    statusprint "Failed to locate kbd package to patch. Aborting.."
    exit 1
  fi
  sudo ./scripts/deb_unpack.sh "$TARGETDEB"
  sudo cp -v "${TARGETDEB}.unp/data/bin/kbd_mode" ./chroot/bin/kbd_mode.dist
  sudo cp -v chroot/bin/true "${TARGETDEB}.unp/data/bin/kbd_mode"
  sudo ./scripts/deb_pack.sh "$TARGETDEB"
  
  statusprint "Moving apt cache to external directory.."
  [ ! -d "./apt.cache" ] && mkdir ./apt.cache
  sudo mv ./chroot/var/cache/apt/archives/* ./apt.cache/

  statusprint "Running debootstrap (stage 2).."
  chroot_exec "/debootstrap/debootstrap --second-stage; apt-mark hold kbd;"

  #statusprint "Restoring original kbd_mode.."
  #sudo cp -v ./chroot/bin/kbd_mode.dist ./chroot/bin/kbd_mode

  statusprint "Adding apt-fast to chroot.."
  sudo cp -v ./scripts/apt-fast/apt-fast ./chroot/usr/bin/apt-fast
  
  statusprint "Debootstrap process completed."
}

if [ -d "./chroot" ]
then
  PRINTOPTIONS=n statusprint "Found existing chroot directory. Please choose what to do:\n 1. Remove existing chroot and re-download.\n 2. Do not re-download, skip this step.\n 3. Abort.\n You choice (1|2|3): "
  read choice

  case $choice in
    1)
      sudo rm -rf ./chroot/
      install_required_package debootstrap
      run_debootstrap_supervised_fast
     ;;
    2)
      statusprint "Download operation skipped. Build continues.."
     ;; 
    *)
      statusprint "Operation aborted. Build stopped."
      exit 1;
     ;;
  esac
else
  install_required_package debootstrap
  run_debootstrap_supervised_fast
fi

exit 0;
