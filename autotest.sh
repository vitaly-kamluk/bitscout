#!/bin/bash
# This file is part of Bitscout remote digital forensics project. 
# Copyright Kaspersky Lab. Contact: bitscout[at]kaspersky.com
# Bitscout is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version. 
# Bitscout is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with
# Bitscout. If not, see <http://www.gnu.org/licenses/>.
export SHELL=/bin/bash

. ./scripts/functions

ISONAME="${PROJECTNAME}-22.04-${GLOBAL_BASEARCH}.iso"
TESTLOG="./autotest.log"
VISIBLE=$(test -z $TERM && echo 0 || echo 1) #show tmux interface during testing
VMRAM=1024 #Megabytes

if [ ! -f "./$ISONAME" ]
then
  echo "Error: couldn't find the ISO file to test at $ISONAME."
  exit 1
fi

install_required_package qemu-kvm
install_required_package socat
install_required_package tmux
install_required_package expect

[ -f "$TESTLOG" ] && rm "$TESTLOG"

dprint()
{
  echo -e "$*" | tee -a "$TESTLOG"
}

DATE=`TZ=UTC date +%c`
dprint "autotest: Started new autotest on $DATE"

TMSESSION="$PROJECTNAME"
TMWINDOW="qemu"

waitfor_socket()
{
  SOCKETPATH="$1"
  dprint "Waiting for socket at $SOCKETPATH .."
  while true
  do
    if [ -S "$SOCKETPATH" ]
    then
      break
    else
      sleep 1
    fi
  done
  return 0
}

vm_keyboard_pushkeys()
{
 while read k;
  do
    tmux send-keys -t:${TMWINDOW}.1 "sendkey $k"
    tmux send-keys -t:${TMWINDOW}.1 "enter"
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
      tmux send-keys -t:${TMWINDOW}.1 "sendkey $c"
      tmux send-keys -t:${TMWINDOW}.1 "enter"
    fi
  done
}

if tmux has-session -t "$TMSESSION" 2>/dev/null >/dev/null
then
  dprint "Found $TMSESSION tmux session.\n Seems that autotest is already running or unfinished. Aborting.."
  exit 0;
fi

[ -S "./${PROJECTNAME}.monitor.sock" ] && dprint "Removing existing monitor socket.."  && rm "./${PROJECTNAME}.monitor.sock"
[ -S "./${PROJECTNAME}.serial.sock" ] && dprint "Removing existing serial socket.." && rm "./${PROJECTNAME}.serial.sock"

dprint "Creating a new local tmux session and starting qemu.." #pane .0
if [ -w /dev/kvm ]
then
  dprint "Using hardware virtualization support.."
  if ! tmux new-session -d -n $TMWINDOW -s $TMSESSION "qemu-system-x86_64 -enable-kvm -name ${PROJECTNAME}-qemu -cpu host -m $VMRAM -cdrom \"./$ISONAME\" -boot order=c -spice port=2001,disable-ticketing -serial unix:./${PROJECTNAME}.serial.sock,server -chardev socket,id=monitordev,server,path=./${PROJECTNAME}.monitor.sock -mon chardev=monitordev -S; tmux wait-for -S $TMSESSION"
  then
    dprint "Failed to start qemu in tmux session. Aborting.."
    exit 1
  else
    dprint "Started qemu in a tmux session."
  fi
else
  dprint "No hardware virtualization support found. Going for software emulation.."
  if ! tmux new-session -d -n $TMWINDOW -s $TMSESSION "qemu-system-x86_64 -name ${PROJECTNAME}-qemu -cpu qemu64 -m $VMRAM -cdrom \"./$ISONAME\" -boot order=c -spice port=2001,disable-ticketing -serial unix:./${PROJECTNAME}.serial.sock,server -chardev socket,id=monitordev,server,path=./${PROJECTNAME}.monitor.sock -mon chardev=monitordev -S; tmux wait-for -S $TMSESSION"
  then
    dprint "Failed to start qemu in tmux session. Aborting.."
    exit 1
  else
    dprint "Started qemu in tmux session."
  fi
fi

dprint "Waiting for the qemu monitor socket.."
waitfor_socket "./${PROJECTNAME}.monitor.sock"

dprint "Attaching to monitor socket.." #pane .1
tmux split-window -v -t "$TMSESSION:$TMWINDOW" -p 90 "socat - ./${PROJECTNAME}.monitor.sock"

dprint "Waiting for the serial port socket.."
waitfor_socket "./${PROJECTNAME}.serial.sock"

dprint "Attaching to the serial port socket.." #pane .2
tmux split-window -h -t "$TMSESSION:$TMWINDOW" -p 90 "./resources/autotest/basic.exp; tmux send-keys -t:$TMWINDOW.1 \"system_powerdown\" && tmux send-keys -t:$TMWINDOW.1 \"enter\" && tmux send-keys -t:$TMWINDOW.1 \"quit\" && tmux send-keys -t:$TMWINDOW.1 \"enter\""
sleep 0.1


dprint "Initiating boot process.."
tmux send-keys -t:$TMWINDOW.1 "cont"
tmux send-keys -t:$TMWINDOW.1 "enter"

#sleep 3
#dprint "Modifying kernel boot options in GRUB.."
#echo -e "e\nenter\ndown\ndown\nend\nleft\nleft\nleft\nleft\nleft" | vm_keyboard_pushkeys
#echo -n " console=tty0 console=ttyS0,115200" | vm_keyboard_typetext
#echo -e "ctrl-x" | vm_keyboard_pushkeys

dprint "To view the VM console use command:\n$ remote-viewer spice://localhost:2001"
if [ $VISIBLE -eq 1 ]
then
 dprint "Attaching to the tmux session.."
 tmux attach -t $TMSESSION
else
 dprint "Waiting for autotest completion..\n(Hint: set VISIBLE=1 in $0 to see VM interaction)."
 tmux wait-for $TMSESSION
fi

echo "Autotest complete. Quick summary:"
grep "^autotest: " ./autotest.log | sed 's/^autotest://g'
