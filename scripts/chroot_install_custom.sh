#!/bin/bash
#
# Installs custom stuff for your own environment
# Xavier Mertens <xavier@rootshell.be>
#

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
   statusprint "Installating custom files in chroot.."

   # ----------------------------------------------
   # Proxy config
   # This is useful to install missing package via
   # a reserve-tunnel through the SSH session
   # ----------------------------------------------
   statusprint "Configuring proxy config.."
   cat <<__APTPROXYCFG__ >build.$GLOBAL_BASEARCH/chroot/etc/apt/apt.conf.d/proxy.conf
Acquire::http::Proxy "http://127.0.0.1:3128/";
Acquire::http::Proxy "http://127.0.0.1:3128/";
__APTPROXYCFG__

   cat <<__BASHPROXYCFG__ >>/etc/bash.bashrc
export HTTP_PROXY="http://127.0.0.1:3128"
export HTTPS_PROXY="http://127.0.0.1:3128"
__BASHPROXYCFG__
   ;;
esac

exit 0;
