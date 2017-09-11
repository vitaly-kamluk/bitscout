#!/bin/bash  
# This file is part of Bitscout 2.0 remote digital forensics project. Copyright
# (c) 2017, Kaspersky Lab. Contact: bitscout[at]kaspersky[.]com
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

statusprint "Removing all temporary files, except configuration.."
sudo rm -rf ./chroot ./chroot.devel ./tmp ./image ./initrd ./recycle ./debootstrap.cache ./apt.cache ./autotest.log ./bitscout.monitor.sock ./bitscout.serial.sock
