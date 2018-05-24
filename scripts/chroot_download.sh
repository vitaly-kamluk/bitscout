#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

PROJECTROOT=$PWD

statusprint "Checking base requirements.."
if [ -z "$(which dpkg-query)" ]
then
 echo "dpkg is required to continue. Please install manually."
 exit 2
fi

apt_make_dirs()
{
  statusprint "Creating directory structure.." &&
  sudo mkdir -p chroot/etc/apt &&
  sudo mkdir -p chroot/var/lib/dpkg &&
  sudo touch chroot/var/lib/dpkg/status &&
  sudo mkdir -p chroot/etc/apt/preferences.d/ &&

  statusprint "Creating sources.list file.." &&
  sudo_file_template_copy resources/etc/apt/sources.list.binary chroot/etc/apt/sources.list  &&
  if [ $GLOBAL_CUSTOMKERNEL -eq 1 ]
  then
    sudo_file_template_copy resources/etc/apt/sources.list.source chroot/etc/apt/sources.list.src  &&
    cat chroot/etc/apt/sources.list.src | sudo tee -a chroot/etc/apt/sources.list >/dev/null &&
    sudo rm chroot/etc/apt/sources.list.src
  fi &&
  statusprint "Backing up sources.list file.." &&
  sudo cp chroot/etc/apt/sources.list chroot/etc/apt/sources.list.bak 
}

apt_update()
{
  statusprint "Downloading PGP keys.." &&
  KEYS=( 40976EAF437D05B5 3B4FE6ACC0B21F32 ) &&
  sudo mkdir -p chroot/etc/apt &&
  for KEY in ${KEYS[*]} 
  do
    sudo apt-key --keyring chroot/etc/apt/trusted.gpg adv --recv-keys --keyserver keyserver.ubuntu.com $KEY
  done &&

  statusprint "Saving PGP key to system-wide keyring.." &&
  sudo mkdir -p chroot/usr/share/keyrings/ &&
  sudo cp chroot/etc/apt/trusted.gpg  chroot/usr/share/keyrings/ubuntu-archive-keyring.gpg &&

  statusprint "Updating $BASERELEASE:$GLOBAL_BASEARCH indexes for chroot.." &&
  sudo apt-get -y -o "Dir=$PWD/chroot" -o "APT::Architecture=$GLOBAL_BASEARCH" -o "Acquire::Languages=$LANG" update
}

apt_fast_download()
{
  DLLIST="$PROJECTROOT/aria2c.task" &&
  statusprint "Fetching URLs of packages to download.." &&
  apt-get -y -o "Dir=$PROJECTROOT/chroot" -o "APT::Architecture=$GLOBAL_BASEARCH" -o "Acquire::Languages=$LANG" --print-uris download $* | awk "/^'/,//" | awk '{gsub("^'"'"'|'"'"'$","",$1); sub("MD5Sum:","md5=",$4); sub("SHA256:","sha-256=",$4); print $1"\n checksum="$4" \n out="$2}' > "$DLLIST" &&

  _MAXNUM=8 &&
  _MAXCONPERSRV=10 &&
  _SPLITCON=8 &&
  _MINSPLITSZ="1M" &&
  _PIECEALGO="default" &&
  sudo aria2c --console-log-level=warn -c -j ${_MAXNUM} -x ${_MAXCONPERSRV} -s ${_SPLITCON} -i ${DLLIST} --min-split-size=${_MINSPLITSZ} --stream-piece-selector=${_PIECEALGO} --connect-timeout=600 --timeout=600 -m0 &&
  rm "$DLLIST"
}

run_debootstrap_supervised_fast()
{
  statusprint "Downloading $BASERELEASE:$GLOBAL_BASEARCH.. " &&
 
  BASEDIR="$PWD" &&
  statusprint "Building base root filesystem.." &&
  DEBDIR="cache/debootstrap.cache/dists/$BASERELEASE/main/binary-$GLOBAL_BASEARCH" &&
  mkdir -p "$DEBDIR" &&

  statusprint "Fetching the list of essential packages.." &&
  DEBS=$(sudo debootstrap --include=aria2,libc-ares2,libssh2-1,libxml2,ca-certificates,zlib1g,localepurge --print-debs --foreign --arch=$GLOBAL_BASEARCH $BASERELEASE chroot ) || exit 1 &&
  install_required_package aria2  &&
 
  chroot_mount_cache "$PWD/chroot" &&
  trap "chroot_unmount_cache \"$PWD/chroot\"" SIGINT SIGKILL SIGTERM &&
  apt_make_dirs &&
  apt_update &&
   
  statusprint "Downloading deb files to local cache dir.." &&
  ( ( cd "$DEBDIR" && apt_fast_download $DEBS ) || echo "Failed to download deb files" ) &&

  statusprint "Scanning/indexing downloaded packages.." &&
  install_required_package dpkg-dev &&
  ( cd "./cache/debootstrap.cache" && dpkg-scanpackages . /dev/null > "dists/$BASERELEASE/main/binary-$GLOBAL_BASEARCH/Packages" 2>/dev/null ) &&
  sed -i 's/^Priority: optional.*/Priority: important/g' "$DEBDIR/Packages" &&

  PKGS_SIZE=$(stat -c %s ./cache/debootstrap.cache/dists/$BASERELEASE/main/binary-$GLOBAL_BASEARCH/Packages) &&
  statusprint "Building local mirror requirements.." &&

  echo "Origin: Ubuntu
Label: Ubuntu
Suite: $BASERELEASE
Version: 18.04
Codename: $BASERELEASE
Architectures: $GLOBAL_BASEARCH
Components: main restricted universe multiverse
Description: Ubuntu Bionic 18.04

MD5Sum:
$(md5sum $DEBDIR/Packages | cut -d' ' -f1) $PKGS_SIZE main/binary-$GLOBAL_BASEARCH/Packages
SHA256:
$(sha256sum $DEBDIR/Packages | cut -d' ' -f1) $PKGS_SIZE main/binary-$GLOBAL_BASEARCH/Packages" > "./cache/debootstrap.cache/dists/$BASERELEASE/Release" &&

  statusprint "Building rootfs based on local deb cache.." &&
  sudo debootstrap --no-check-gpg --foreign --arch=$GLOBAL_BASEARCH $BASERELEASE chroot "file:///$BASEDIR/cache/debootstrap.cache" &&

  statusprint "Fixing keyboard-configuration GDM compatibility bug (divert kbd_mode).." &&
  TARGETDEB="./chroot$(grep "^kbd " chroot/debootstrap/debpaths | cut -d' ' -f2)" &&
  if [ "$TARGETDEB" == "./chroot" ]
  then
    statusprint "Failed to locate kbd package to patch. Aborting.."
    exit 1
  else
    statusprint "Located kbd package in $TARGETDEB"
  fi &&
  sudo ./scripts/deb_unpack.sh "$TARGETDEB" &&
  sudo cp -v "${TARGETDEB}.unp/data/bin/kbd_mode" ./chroot/bin/kbd_mode.dist &&
  sudo cp -v chroot/bin/true "${TARGETDEB}.unp/data/bin/kbd_mode" &&
  sudo ./scripts/deb_pack.sh "$TARGETDEB" &&

  chroot_unmount_cache "$PWD/chroot" &&

  statusprint "Backing up apt lists before deboostrap (stage 2).." &&
  sudo cp -r cache/apt.lists/ cache/apt.lists.bak &&

  statusprint "Running debootstrap (stage 2).." &&
  chroot_exec chroot "/debootstrap/debootstrap --second-stage && apt-mark hold kbd" &&

  statusprint "Restoring apt lists after debootstrap (stage 2).." &&
  sudo rm -rf cache/apt.lists/ &&
  sudo mv cache/apt.lists.bak cache/apt.lists &&
 
  statusprint "Restoring sources.list file after debootstrap (stage 2).." &&
  sudo cp chroot/etc/apt/sources.list.bak chroot/etc/apt/sources.list &&

  statusprint "Adding apt-fast to chroot.." &&
  sudo cp -v ./resources/apt-fast/apt-fast ./chroot/usr/bin/apt-fast &&
  
  statusprint "Debootstrap process completed." && return 0
}

if [ -d "./chroot" ]
then
  PRINTOPTIONS=n statusprint "Found existing chroot directory. Please choose what to do:\n 1. Remove existing chroot and re-download.\n 2. Do not re-download, skip this step.\n 3. Abort.\n You choice (1|2|3): "
  read choice

  case $choice in
    1)
      sudo rm -rf ./chroot/ &&
      install_required_package debootstrap &&
      run_debootstrap_supervised_fast || exit 1
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
  install_required_package debootstrap &&
  run_debootstrap_supervised_fast || exit 1
fi

exit 0;
