#!/bin/bash -xe
# Run this outside of debuild/rpmbuild process

cd src

. config.sh

bundle package --no-install

rm -rf ruby.tar.xz ruby/
curl -SsfLo ruby.tar.xz "${ITAMAE_RUBY_URL}"
echo "${ITAMAE_RUBY_SHA256} ruby.tar.xz" | sha256sum --strict -c
mkdir ruby
tar xf ./ruby.tar.xz --strip-components=1 -C ruby
rm ./ruby.tar.xz
rm -rf ruby/gems/*
echo > ruby/gems/bundled_gems
