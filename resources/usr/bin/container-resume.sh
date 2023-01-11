#!/bin/sh
#Resume all processess withing container
machinectl kill container --signal=CONT

#The second pass seems to be required to restore container I/O
machinectl kill container --signal=CONT
