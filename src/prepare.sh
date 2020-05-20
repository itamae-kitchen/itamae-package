#!/bin/bash
# Run this outside of debuild/rpmbuild process

DIST=$(lsb_release -sc)

. config.sh

sed -i -e "s/ITAMAE_VERSION/${ITAMAE_VERSION}/g" debian/changelog
sed -i -e "s/PKGREV/${PKGREV}/g" debian/changelog
sed -i -e "s/DIST/${DIST}/g" debian/changelog


cd /build/itamae
mk-build-deps -r -i -t 'apt-get -y -o Debug::pkgProblemResolver=yes --no-install-recommends' debian/control

mkdir -p /opt
chown buildbot /opt
