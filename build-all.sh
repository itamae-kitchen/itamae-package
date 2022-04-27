#!/bin/bash -xe

for x in trusty xenial bionic focal jammy stretch buster; do
  ./build.sh ${x}
done
