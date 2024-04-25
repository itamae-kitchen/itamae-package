#!/bin/bash
# Run this outside of debuild/rpmbuild process

DIST=$(lsb_release -sc)

. config.sh

sed -i -e "s/ITAMAE_VERSION/${ITAMAE_VERSION}/g" debian/changelog
sed -i -e "s/PKGREV/${PKGREV}/g" debian/changelog
sed -i -e "s/DIST/${DIST}/g" debian/changelog
sed -i -e "s/PKGDATE/${PKGDATE}/g" debian/changelog

if [ "_${DIST}" = "_trusty" -o "_${DIST}" = "_xenial" ]; then
  echo 9 > debian/compat
  sed -i -e "s/^  debhelper .\+,$/  debhelper (>= 9),/" debian/control
fi

cd /build/itamae
./prebuild.sh
