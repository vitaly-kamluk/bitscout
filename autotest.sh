#!/bin/bash
# This file is part of Bitscout 2.0 remote digital forensics project. 
# Copyright (c) 2017, Kaspersky Lab. Contact: bitscout[at]kaspersky[.]com
# Bitscout is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version. 
# Bitscout is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with
# Bitscout. If not, see <http://www.gnu.org/licenses/>.

. ./scripts/functions

ISONAME="${PROJECTNAME}-16.04.iso"
TESTLOG="./autotest.log"

install_required_package qemu-kvm
install_required_package socat
install_required_package tmux
install_required_package expect

[ -f "$TESTLOG" ] && rm "$TESTLOG"

dprint()
{
  echo $* >> "$TESTLOG"
  echo $*
}

DATE=`TZ=UTC date +%c`
dprint "autotest: Started new autotest on $DATE"

TMSESSION="$PROJECTNAME"
TMWINDOW="qemu"

vm_keyboard_pushkeys()
{
  while read k;
  do
    tmux send-keys -t:$TMSESSION.1 "sendkey $k"
    tmux send-keys -t:$TMSESSION.1 "enter"
  done
}

vm_keyboard_typetext()
{
  while IFS="" read -r -n1 c;
  do
    case "$c" in
     [[:space:]]) 
       c="spc"
     ;;
     "=")
       c="equal"
     ;;
     ",")
       c="comma"
     ;;
     [[:upper:]] )
       c="shift-"${c,}
     ;;
    esac
    if [ -n "$c" ]
    then
      tmux send-keys -t:$TMSESSION.1 "sendkey $c"
      tmux send-keys -t:$TMSESSION.1 "enter"
    fi
  done
}

if tmux has-session -t "$TMSESSION" 2>/dev/null >/dev/null
then
  dprint "Found $TMSESSION tmux session.\n Seems that autotest is already running or unfinished. Aborting.."
  exit 0;
fi

dprint "Creating new local tmux session.." #pane .0
if ! tmux new-session -d -n $TMWINDOW -s $TMSESSION "qemu-system-x86_64 -enable-kvm -name ${PROJECTNAME}-qemu -cpu host -m 256 -cdrom "./$ISONAME" -boot order=c -spice port=2001,disable-ticketing -vga cirrus -serial unix:./${PROJECTNAME}.serial.sock,server -chardev socket,id=monitordev,server,path=./${PROJECTNAME}.monitor.sock -mon chardev=monitordev -S"
then
  echo "Failed to start qemu in tmux session. Aborting.."
  exit 1
fi
sleep 0.3

dprint "Attaching to monitor socket.." #pane .1
tmux split-window -v -t "$TMSESSION:$TMWINDOW" -p 80 "socat - ./${PROJECTNAME}.monitor.sock"
sleep 0.1

dprint "Attaching to serial port socket.." #pane .2
tmux split-window -h -t "$TMSESSION:$TMWINDOW" -p 75 "./resources/autotest/basic.exp"
sleep 0.1

dprint "Initiating boot process.."
tmux send-keys -t:$TMSESSION.1 "cont"
tmux send-keys -t:$TMSESSION.1 "enter"

sleep 3
dprint "Modifying kernel boot options in GRUB.."
echo -e "e\nenter\ndown\ndown\nend\nleft\nleft\nleft\nleft\nleft" | vm_keyboard_pushkeys
echo -n " console=tty0 console=ttyS0,115200" | vm_keyboard_typetext
echo -e "ctrl-x" | vm_keyboard_pushkeys

dprint "Attaching to tmux session.."
tmux attach -t $TMSESSION

dprint "Autotest complete. Quick summary:"
grep "^autotest: " ./autotest.log | sed 's/^autotest://g'
