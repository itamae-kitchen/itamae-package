#!/bin/bash -xe

. config.sh

# buildopt=--build=${ITAMAE_BUILD_TYPE:-full}
buildopt=
if [[ "_${ITAMAE_BUILD_TYPE:-full}" = "_any" ]]; then
  buildopt=-B
fi
debuild -us -uc ${buildopt}

cd ..
cat itamae/debian/files | cut -d' ' -f1 | xargs cp -v -t /work/out/
cp -v *.{dsc,changes} /work/out/ || :
cp -v *.debian.tar* /work/out/ || :
cp -v *.tar* /work/out/ || :
