#!/bin/bash
mk-build-deps -r -i -t 'apt-get -y -o Debug::pkgProblemResolver=yes --no-install-recommends' debian/control

mkdir -p /opt
chown buildbot /opt
