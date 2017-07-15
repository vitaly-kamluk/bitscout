#!/bin/bash
DEB=`basename "$1"`
pushd . >/dev/null &&
mkdir "$1.unp" &&
cd "$1.unp/" &&
ar x "../$DEB" &&
mkdir data control &&
cd data &&
tar xf ../data.tar.xz &&
cd ../control &&
tar xf ../control.tar.gz
popd >/dev/null
