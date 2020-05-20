#!/bin/bash -xe
useradd -u ${BUILDBOT_UID:-1999} -m buildbot
chown buildbot:buildbot /home/buildbot

mkdir -p /build/itamae
tar xf /work/source.tar* -C /build/itamae

if [ ! -e /work/out ]; then
  mkdir -p /work/out
  chown -R buildbot:buildbot /work/out
fi

cd /build/itamae
./prepare.sh
chown -R buildbot:buildbot /build
su buildbot -c 'bash -xe ./build.sh'
chown ${BUILDBOT_UID:-1999}:${BUILDBOT_GID:-1999} /work/out/*
