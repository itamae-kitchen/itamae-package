#!/bin/bash -xe

for x in trusty xenial bionic focal stretch buster; do
  ./build.sh ${x}
done
