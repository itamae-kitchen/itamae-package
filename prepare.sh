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

curl -SsfLo openssl-2.2.1.gem https://rubygems.org/gems/openssl-2.2.1.gem
echo "f6afbf4b66f3fcd3c08dc1da1ddd2245b76c19d0ea2dd7e2c8b55794ca1a7d72  openssl-2.2.1.gem" | sha256sum --strict -c
