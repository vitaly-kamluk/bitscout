#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Adding local user.."
if ! grep -qF "${CONTAINERUSERNAME}:x:999:999:Local user,,,:/home/${CONTAINERUSERNAME}:/bin/bash" ./build.$GLOBAL_BASEARCH/chroot/etc/passwd
then
  echo "${CONTAINERUSERNAME}:x:999:999:Local user,,,:/home/${CONTAINERUSERNAME}:/bin/bash" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/passwd >/dev/null
fi

statusprint "Adding ${CONTAINERUSERNAME} to local groups.."
if ! grep -qF "${CONTAINERUSERNAME}:x:999:" ./build.$GLOBAL_BASEARCH/chroot/etc/group
then
  sudo sed -i 's/^\(\(adm\|cdrom\|sudo\|dip\|plugdev\):.*[^:]$\)/\1,'"${CONTAINERUSERNAME}"'/; s/^\(\(adm\|cdrom\|sudo\|dip\|plugdev\):.*:$\)/\1'"${CONTAINERUSERNAME}"'/;' ./build.$GLOBAL_BASEARCH/chroot/etc/group
  echo "${CONTAINERUSERNAME}:x:999:" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/group >/dev/null
fi

statusprint "Setting empty password for \"${CONTAINERUSERNAME}\".."
if ! sudo grep -qF "${CONTAINERUSERNAME}:U6aMy0wojraho:17072:0:99999:7:::" ./build.$GLOBAL_BASEARCH/chroot/etc/shadow
then
  echo "${CONTAINERUSERNAME}:U6aMy0wojraho:17072:0:99999:7:::" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/shadow 2>/dev/null
fi

statusprint "Creating ${CONTAINERUSERNAME}'s home dir and default files.."
sudo mkdir ./build.$GLOBAL_BASEARCH/chroot/home/${CONTAINERUSERNAME} 2>&-
find ./build.$GLOBAL_BASEARCH/chroot/etc/skel -type f | xargs -I {} sudo cp -v {} ./build.$GLOBAL_BASEARCH/chroot/home/${CONTAINERUSERNAME}/
sudo chown -R 999:999 ./build.$GLOBAL_BASEARCH/chroot/home/${CONTAINERUSERNAME}

exit 0;
