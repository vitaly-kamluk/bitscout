#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

UNPACKED_INITRD=0
if [ ! -d "initrd" ]
then
  statusprint "Unpacking initrd.."
  scripts/initrd_unpack.sh
  UNPACKED_INITRD=1
fi

statusprint "Fixing casper find_livefs method.."
if [ -f "initrd/scripts/casper" ]
then
  if ! grep -q "bitscoutfix_find_livefs()" initrd/scripts/casper
  then
    sed -i 's/^find_livefs() {/bitscoutfix_find_livefs() {/' initrd/scripts/casper
    echo "
find_livefs() {
  srcdevice=\$(blkid -L \"${PROJECTNAME}-${GLOBAL_BUILDID}\")
  if [ -z \"\$(blkid \$srcdevice)\" ] && blkid \${srcdevice%%?} | grep -q \"${PROJECTNAME}-${GLOBAL_BUILDID}\"
  then
    srcdevice=\"\${srcdevice%%?}\"
  fi
  mount -t \$(get_fstype \"\$srcdevice\") -o ro,noatime \"\$srcdevice\" \"\$mountpoint\"
  echo \"\$mountpoint\"
  return 0
}" >> initrd/scripts/casper
  fi
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi

exit 0;
