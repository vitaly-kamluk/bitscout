#!/bin/bash
#
# Installs extra forensics tools
# Xavier Mertens <xavier@rootshell.be>

. ./scripts/functions

BASEDIRECTORY=`pwd`

scriptname=`basename $0`
err_report() {
        echo "Error in ${scriptname}, line $1"
        exit 1
}

trap 'err_report $LINENO' ERR

case $GLOBAL_RELEASESIZE in
 1)
   ;;
 2)
   ;;
 3)
   statusprint "Installing extra forensics packages in chroot.."

   [ ! -d "build.$GLOBAL_BASEARCH/tmp/" ] && mkdir -p build.$GLOBAL_BASEARCH/tmp
   [ ! -d "build.$GLOBAL_BASEARCH/chroot/opt" ] && sudo mkdir -p build.$GLOBAL_BASEARCH/chroot/opt

   # -------------
   # Install byobu
   # -------------
   statusprint "Installing Byobu.."
   if [ ! -x "build.$GLOBAL_BASEARCH/chroot/usr/bin/byobu" ]
   then
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'apt-get -y install byobu'
   else
       statusprint "Byobu already installed.."
   fi

   # --------------
   # Install rip.pl
   # --------------
   statusprint "Installing RegRipper.."
   if [ ! -d "build.$GLOBAL_BASEARCH/chroot/opt/regripper" ]
   then
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'export DEBIAN_FRONTEND=noninteractive; apt-get -y install libparse-win32registry-perl unzip'
       wget -O build.$GLOBAL_BASEARCH/tmp/master.zip https://github.com/keydet89/RegRipper3.0/archive/master.zip
       sudo mv -v build.$GLOBAL_BASEARCH/tmp/master.zip build.$GLOBAL_BASEARCH/chroot/opt/
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'unzip -o /opt/master.zip -d /opt/ && mv /opt/RegRipper3.0-master /opt/regripper && rm /opt/master.zip'
   else
       statusprint "RegRipper already installed.."
   fi

   # ----------------------
   # Install bulk_extractor
   # ----------------------
   statusprint "Installing bulk_extractor.."
   if [ ! -x "/opt/bitscout/build.amd64/chroot/usr/local/bin/bulk_extractor" ]
   then
       [ -d "build.$GLOBAL_BASEARCH/chroot/opt/bulk_extractor" ] && sudo rm -rf "build.$GLOBAL_BASEARCH/chroot/opt/bulk_extractor"

       [ ! -d "build.$GLOBAL_BASEARCH/tmp/bulk_extractor" ] && git clone --recursive --depth=1 https://github.com/simsong/bulk_extractor.git build.$GLOBAL_BASEARCH/tmp/bulk_extractor
       sudo cp -r build.$GLOBAL_BASEARCH/tmp/bulk_extractor build.$GLOBAL_BASEARCH/chroot/opt/
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'export DEBIAN_FRONTEND=noninteractive; aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
       apt-fast --yes install autoconf openjdk-11-jdk flex git libssl-dev zlib1g-dev || exit 1;
       cd /opt/bulk_extractor; 
       source bootstrap.sh;
       ./configure --prefix=/usr/local --disable-BEViewer &&
       make -j'$((`nproc`+1))' install &&
       cd /opt && rm -rf /opt/bulk_extractor'
   else
       statusprint "bulk_extractor already installed.."
   fi

   # ------------
   # Install Loki
   # ------------
   statusprint "Installing Loki.."
   if [ ! -d "build.$GLOBAL_BASEARCH/chroot/opt/loki" ]
   then
       [ ! -d "build.$GLOBAL_BASEARCH/tmp/loki" ] && git clone --recursive --depth=1 https://github.com/Neo23x0/Loki.git build.$GLOBAL_BASEARCH/tmp/loki
       sudo cp -r build.$GLOBAL_BASEARCH/tmp/loki build.$GLOBAL_BASEARCH/chroot/opt/
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'export DEBIAN_FRONTEND=noninteractive; \
       apt-get -y install python-pip &&\
       cd /opt/loki &&\
       pip install -r requirements.txt &&\
       rm -rf ./.git &&\
       python2 ./loki-upgrader.py'
   else
       statusprint "Loki already installed.."
   fi

   ;;
esac

exit 0;
