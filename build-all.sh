#!/bin/bash -xe

for x in xenial bionic focal jammy noble buster bookworm; do
  ./build.sh ${x}
done
