#!/bin/bash
#
# Enable remote syslog support and compile bash with syslog support
# Xavier Mertens <xavier@rootshell.be>

. ./scripts/functions

scriptname=`basename $0`
err_report() {
	echo "Error in ${scriptname}, line $1"
	exit 1
}

BASHVER="5.0"
SRCARCHIVE="bash-$BASHVER.tar.gz"
SRCURL="https://ftp.gnu.org/gnu/bash/$SRCARCHIVE"

trap 'err_report $LINENO' ERR

statusprint "Enabling syslog setup for Bitscout remote activity logging.."

# Create remote logging configuration if the syslog server is enabled
if [ -n "${GLOBAL_SYSLOGSERVER}" -a "${GLOBAL_SYSLOGSERVER}" != "none" ]
then
	statusprint "Configuring local rsyslog.."
	cat <<__END__ | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/rsyslog.d/40-remote.conf >/dev/null
*.*	@${GLOBAL_SYSLOGSERVER}:514
__END__
  [ ! -d "build.$GLOBAL_BASEARCH/tmp" ] &&  mkdir build.$GLOBAL_BASEARCH/tmp

	if [ ! -x build.$GLOBAL_BASEARCH/tmp/bash-5.0/bash ]
	then
		statusprint "Compiling bash with syslog support.."
		BASEDIR=`pwd`
		cd build.$GLOBAL_BASEARCH/tmp
    if [ ! -r "$SRCARCHIVE" ]
    then
      statusprint "Downloading bash sourcecode from $SRCURL.."
  		curl -o "$SRCARCHIVE" "$SRCURL"
    fi

		if [ -r "$SRCARCHIVE" ]
		then
		  statusprint "Compiling bash with syslog support.."
			tar xzf $SRCARCHIVE
			cd bash-$BASHVER
			export CFLAGS="-DSYSLOG_SHOPT -DSYSLOG_HISTORY"
			./configure --prefix=/
			make
      cd "$BASEDIR"
		else
			statusprint "Couldn't find bash source code. Expected in build.$GLOBAL_BASEARCH/tmp/$SRCARCHIVE"
			exit 1;
	  fi
	else
    statusprint "Bash binary has already been compiled."
  fi

  statusprint "Replacing standard bash with syslog-enabled variant.."
	sudo cp -v build.amd64/tmp/bash-$BASHVER/bash ./build.$GLOBAL_BASEARCH/chroot/bin/
fi

exit 0;
