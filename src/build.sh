#!/bin/bash -xe

. config.sh

debuild -us -uc --build=${ITAMAE_BUILD_TYPE:-full}

cd ..
cat itamae/debian/files | cut -d' ' -f1 | xargs cp -v -t /work/out/
cp -v *.{dsc,changes} /work/out/ || :
cp -v *.debian.tar* /work/out/ || :
cp -v *.tar* /work/out/ || :
