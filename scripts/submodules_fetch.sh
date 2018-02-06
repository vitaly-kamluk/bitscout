#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Updating submodules.." &&
install_required_package git &&
git submodule init &&
git submodule update &&

exit 0;
