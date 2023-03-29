#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

irc_template_copy()
{
  SRCFILE="$1"
  DSTFILE="$2"  
  [ ! -d "${DSTFILE%/*}" ] && $SUDO mkdir -p "${DSTFILE%/*}"
  echo "'$SRCFILE' -> '$DSTFILE'"
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<PROJECTNAME>/${PROJECTNAME}/g; s/<IRC_SERVER>/${IRC_SERVER}/g; s/<IRC_PORT>/${IRC_PORT}/g; s/<IRCOPPASS>/$GLOBAL_IRCOPPASS/g; " "$SRCFILE" > "$DSTFILE"
}

if ! grep -q "^GLOBAL_IRCOPPASS" "config/${PROJECTNAME}-build.conf"
then
  statusprint "Generating IRC operator pass.."
  GLOBAL_IRCOPPASS=$(dd if=/dev/urandom bs=1 count=8 2>/dev/null | xxd -pos)

  statusprint "Saving IRC operator pass in global config.."
  echo "GLOBAL_IRCOPPASS=\"${GLOBAL_IRCOPPASS}\"" >> "config/${PROJECTNAME}-build.conf"
fi

statusprint "Creating irssi client logs directory.."
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/var/log/irssi

statusprint "Copying irssi client configuration.."
if [ ! -f "config/irssi/irssi.conf" ]
then
 irc_template_copy "resources/irssi/irssi.conf.client" "config/irssi/irssi.conf"
fi
sudo cp -v config/irssi/irssi.conf ./build.$GLOBAL_BASEARCH/chroot/etc/irssi.conf

statusprint "Copying server irssi configuration.."
if [ ! -f "config/ngircd/ngircd.conf" ]
then
 irc_template_copy "resources/etc/ngircd/ngircd.conf" "config/ngircd/ngircd.conf"
fi


exit 0;
