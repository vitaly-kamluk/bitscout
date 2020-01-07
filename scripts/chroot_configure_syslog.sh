#!/bin/bash
#
# Enable remote syslog support and compile bash with Syslog support
# Xavier Mertens <xavier@rootshell.be>

. ./scripts/functions

# Create remote logging confguration
if grep -q "^GLOBAL_SYSLOGSERVER" "config/${PROJECTNAME}-build.conf"
then
	statusprint "Configuring RSyslog.."
	cat <<__END__ >./build.$GLOBAL_BASEARCH/chroot/etc/rsyslog.d/40-remote.conf
*.*	@${GLOBAL_SYSLOGSERVER}:514
__END__
fi

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
		statusprint "Cannot compile bash.."
		exit 1;
	fi
else
	statusprint "Replacing bash with Syslog support.."
	cp build.amd64/tmp/bash-5.0/bash ./build.$GLOBAL_BASEARCH/chroot/bin
fi

exit 0;
