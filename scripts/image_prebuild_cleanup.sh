#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

RECYCLEDIR="./recycle"

statusprint "Pre-build cleanup.."

#statusprint "Removing GDM kbd_mode fix.."

statusprint "Removing packages which are not essential anymore.."
if [ ${GLOBAL_RELEASESIZE} -eq 1 ]
then
  chroot_exec 'export DEBIAN_FRONTEND=noninteractive
  apt-get --yes ca-certificates python3-requests ssh-import-id python3-chardet python3-pkg-resources python3-six python3-urllib3
geoip-database krb5-locales libavahi-client3 libavahi-common3 libcups2 python-samba samba-common-bin samba-libs wget'
fi

chroot_exec 'export DEBIAN_FRONTEND=noninteractive
apt-get --yes purge plymouth python-samba samba-common samba-common-bin samba-libs cifs-utils
apt-get --yes install deborphan
while true; do
    if [[ $(deborphan --guess-all) ]]; then
        apt-get --yes purge `deborphan --guess-all`
        apt-get --yes autoremove --purge
    else
        break
    fi
done
apt-get --yes purge deborphan
apt-get --yes clean'

statusprint "Removing .pyc files cache.."
sudo find ./chroot/ -iname "*.pyc" 2>&- | while read f; do sudo rm "$f" 2>&-; done 

statusprint "Cleaning APT cache.."
sudo rm -rf chroot/var/lib/apt/lists/*

if [ ${GLOBAL_RELEASESIZE} -eq 1 ]
then
  mkdir "$RECYCLEDIR" 2>&-

  statusprint "Moving non-essential firmware files (sound,video,tuners,etc) to recycle dir.."
  DDIR="$RECYCLEDIR/lib/firmware"
  mkdir -p "$DDIR" 2>&-
  SDIR="chroot/lib/firmware"
  sudo mv "$SDIR/ess/" "$SDIR/korg/" "$SDIR/yamaha/" "$SDIR/ttusb-budget/" "$SDIR/keyspan/" "$SDIR/emi26/" "$SDIR/emi62/" "$SDIR/ti_3410.fw" "$SDIR/ti_5052.fw" "$SDIR/whiteheat"* "$SDIR/cpia2/" "$SDIR/vicam/" "$SDIR/dsp56k/" "$SDIR/sb16/" "$SDIR/ql2"* "$SDIR/v4l-"* "$SDIR/dvb-"* "$SDIR/yam/" "$SDIR/av7110/" "$SDIR/matrox/" "$SDIR/r128/" "$SDIR/radeon/" "$SDIR/f2255usb.bin" "$SDIR/go7007/" "$SDIR/s2250"* "$SDIR/lgs8g75.fw" "$SDIR/ueagle-atm" "$SDIR/tlg2300_firmware.bin" "$SDIR/ar3k/" "$SDIR/s5p-mfc"* "$SDIR/ea/" "$SDIR/asihpi/"  "$DDIR/" 2>&-


  statusprint "Moving non-essential kernel drivers (gpu,media,etc) to recycle dir.."
  KERNELVER=`ls -1 ./chroot/lib/modules/| head -n1` #shall be just one kernel directory anyway
  DDIR="$RECYCLEDIR/lib/modules/$KERNELVER/kernel/drivers"
  mkdir -p "$DDIR" 2>&-
  SDIR="chroot/lib/modules/$KERNELVER/kernel/drivers"
  sudo mv "$SDIR/media" "$SDIR/gpu"  "$DDIR/" 2>&-


  statusprint "Moving (arguably) ambiguous files to recyle dir.."
  #DDIR="$RECYCLEDIR/var/lib/dpkg/info"; mkdir -p "$DDIR" 2>&-;
  #sudo mv chroot/var/lib/dpkg/info/* "$DDIR/" 2>&-

  DDIR="$RECYCLEDIR/var/cache"; mkdir -p "$DDIR" 2>&-;
  sudo mv chroot/var/cache/* "$DDIR/" 2>&-

  DDIR="$RECYCLEDIR/usr/share/X11"; mkdir -p "$DDIR" 2>&-;
  sudo mv chroot/usr/share/X11/* "$DDIR/" 2>&-

  DDIR="$RECYCLEDIR/usr/share/grub"; mkdir -p "$DDIR" 2>&-;
  sudo mv chroot/usr/share/grub/* "$DDIR/" 2>&-

  DDIR="$RECYCLEDIR/usr/share/locale"; mkdir -p "$DDIR" 2>&-;
  ls -Fd1 chroot/usr/share/locale/*| grep "/$"| grep -v "./en/"| while read d; do sudo mv "$d" "$DDIR/" 2>&-; done

fi

sudo rm -rf chroot/tmp/*

exit 0;
