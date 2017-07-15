#!/bin/bash
DEB=`basename "$1"`
pushd . >/dev/null &&
cd "$1.unp/control" &&
tar cfz ../control.tar.gz ./* &&
cd ../ &&
rm -r ./control &&
cd data &&
tar cfJ ../data.tar.xz ./* &&
cd ../ &&
rm -r ./data &&
ar r "../$DEB" ./* &&
cd ../ &&
rm -r "$DEB.unp/"
popd >/dev/null
