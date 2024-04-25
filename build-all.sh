#!/bin/bash -xe

for x in trusty xenial bionic focal jammy noble stretch buster bookworm; do
  ./build.sh ${x}
done
