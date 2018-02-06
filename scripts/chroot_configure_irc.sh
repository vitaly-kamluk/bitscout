#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Copying client irssi configuration.."
if [ ! -f "config/irssi/irssi.conf" ]
then
 file_template_copy "resources/irssi/irssi.conf.client" config/irssi/irssi.conf
fi
sudo cp -v config/irssi/irssi.conf chroot/etc/irssi.conf

statusprint "Copying server irssi configuration.."
mkdir config/ngircd 2>&-
if [ ! -f "config/ngircd/ngircd.conf" ]
then
 file_template_copy "resources/etc/ngircd/ngircd.conf" config/ngircd/ngircd.conf
fi

if ! grep -q "^GLOBAL_IRCOPPASS" "config/${PROJECTNAME}-build.conf"
then
  statusprint "Generating IRC operator pass.."
  GLOBAL_IRCOPPASS=$(dd if=/dev/urandom bs=1 count=8 2>/dev/null | xxd -pos)

  statusprint "Saving IRC operator pass in global config.."
  echo "GLOBAL_IRCOPPASS=\"${GLOBAL_IRCOPPASS}\"" >> "config/${PROJECTNAME}-build.conf"
fi

sed -i "s/<IRCOPPASS>/$GLOBAL_IRCOPPASS/g" config/ngircd/ngircd.conf

exit 0;
