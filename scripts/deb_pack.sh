#!/bin/bash
DEB=`basename "$1"`
pushd . >/dev/null &&
cd "$1.unp/control" &&
tar --zstd --create --file ../control.tar.zst ./* &&
cd ../ &&
rm -r ./control &&
cd data &&
tar --zstd --create --file ../data.tar.zst ./* &&
cd ../ &&
rm -r ./data &&
ar r "../$DEB" ./* &&
cd ../ &&
rm -r "$DEB.unp/" &&
popd >/dev/null
