#!/bin/bash
#
# Enable remote syslog support and compile bash with Syslog support
# Xavier Mertens <xavier@rootshell.be>

. ./scripts/functions

scriptname=`basename $0`
err_report() {
	echo "Error in ${scriptname}, line $1"
	exit 1
}

trap 'err_report $LINENO' ERR

# Create remote logging confguration if a syslog server is enabled
if [ "${GLOBAL_SYSLOGSERVER}" != "" ]
then
	statusprint "Configuring RSyslog.."
	cat <<__END__ >./build.$GLOBAL_BASEARCH/chroot/etc/rsyslog.d/40-remote.conf
*.*	@${GLOBAL_SYSLOGSERVER}:514
__END__

	if [ ! -x build.amd64/tmp/bash-5.0/bash ]
	then
		statusprint "Compiling bash with Syslog support.."
		BASEDIR=`pwd`
		cd build.amd64/tmp
		curl -o bash-5.0.tar.gz http://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz
		if [ -r bash-5.0.tar.gz ]
		then
			tar xzf bash-5.0.tar.gz
			cd bash-5.0
			export CFLAGS="-DSYSLOG_SHOPT -DSYSLOG_HISTORY"
			./configure --prefix=/
			make
			cp bash $BASEDIR/build.$GLOBAL_BASEARCH/chroot/bin
		else
			statusprint "Cannot download bash source code.."
			exit 1;
		fi
	else
		statusprint "Replacing bash with Syslog support.."
		cp build.amd64/tmp/bash-5.0/bash ./build.$GLOBAL_BASEARCH/chroot/bin
	fi
fi

exit 0;
