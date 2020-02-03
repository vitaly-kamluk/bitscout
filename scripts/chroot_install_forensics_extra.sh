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
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'apt-get -y install libparse-win32registry-perl'
       mkdir -p build.$GLOBAL_BASEARCH/chroot/opt
       cd build.$GLOBAL_BASEARCH/chroot/opt
       wget https://github.com/keydet89/RegRipper2.8/archive/master.zip
       unzip -o master.zip
       mv RegRipper2.8-master regripper
       rm master.zip
   else
       statusprint "RegRipper already installed.."
   fi

   # ----------------------
   # Install bulk_extractor
   # ----------------------
   statusprint "Installing bulk_extractor.."
   if [ ! -x "/opt/bitscout/build.amd64/chroot/usr/local/bin/bulk_extractor" ]
   then
       cd $BASEDIRECTORY
       mkdir -p build.$GLOBAL_BASEARCH/chroot/opt
       git clone https://github.com/simsong/bulk_extractor.git build.$GLOBAL_BASEARCH/chroot/opt/bulk_extractor
       cd build.$GLOBAL_BASEARCH/chroot/opt/bulk_extractor
       source bootstrap.sh
       cd $BASEDIRECTORY
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'apt-get -y install openjdk-11-jdk flex git libssl-dev zlib1g-dev'
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'cd /opt/bulk_extractor && ./configure --prefix=/usr/local --disable-BEViewer && make install'
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'cd /opt/bulk_extractor && make clean'
   else
       statusprint "bulk_extractor already installed.."
   fi

   # ------------
   # Install Loki
   # ------------
   statusprint "Installing Loki.."
   if [ ! -d "build.$GLOBAL_BASEARCH/chroot/opt/loki" ]
   then
       cd $BASEDIRECTORY
       mkdir -p build.$GLOBAL_BASEARCH/chroot/opt
       git clone https://github.com/Neo23x0/Loki.git build.$GLOBAL_BASEARCH/chroot/opt/loki
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'apt-get -y install python-pip'
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'cd /opt/loki && pip install -r requirements.txt'
       chroot_exec build.$GLOBAL_BASEARCH/chroot 'cd /opt/loki && python loki-upgrader.py'
   else
       statusprint "Loki already installed.."
   fi

   ;;
esac

exit 0;
