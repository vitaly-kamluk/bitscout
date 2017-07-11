#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Adding local user.."
if ! grep -qF "${CONTAINERUSERNAME}:x:999:999:Local user,,,:/home/${CONTAINERUSERNAME}:/bin/bash" chroot/etc/passwd
then
  echo "${CONTAINERUSERNAME}:x:999:999:Local user,,,:/home/${CONTAINERUSERNAME}:/bin/bash" | sudo tee -a chroot/etc/passwd >/dev/null
fi

statusprint "Adding ${CONTAINERUSERNAME} to local groups.."
if ! grep -qF "${CONTAINERUSERNAME}:x:999:" chroot/etc/group
then
  sudo sed -i 's/^\(\(adm\|cdrom\|sudo\|dip\|plugdev\):.*[^:]$\)/\1,'"${CONTAINERUSERNAME}"'/; s/^\(\(adm\|cdrom\|sudo\|dip\|plugdev\):.*:$\)/\1'"${CONTAINERUSERNAME}"'/;' chroot/etc/group
  echo "${CONTAINERUSERNAME}:x:999:" | sudo tee -a chroot/etc/group >/dev/null
fi

statusprint "Setting empty password for \"${CONTAINERUSERNAME}\".."
if ! sudo grep -qF "${CONTAINERUSERNAME}:U6aMy0wojraho:17072:0:99999:7:::" chroot/etc/shadow
then
  echo "${CONTAINERUSERNAME}:U6aMy0wojraho:17072:0:99999:7:::" | sudo tee -a chroot/etc/shadow 2>/dev/null
fi

statusprint "Creating ${CONTAINERUSERNAME}'s home dir and default files.."
sudo mkdir chroot/home/${CONTAINERUSERNAME} 2>&-
find chroot/etc/skel -type f | xargs -I {} sudo cp -v {} chroot/home/${CONTAINERUSERNAME}/
sudo chown -R 999:999 chroot/home/${CONTAINERUSERNAME}

exit 0;
