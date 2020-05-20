#!/bin/bash -xe

export ITAMAE_PACKAGE_INSTALL_GEM_TO_OPT=1

/opt/itamae/embedded/bin/ruby -rrubygems -e 'raise "no operating_system loaded" if $".grep(/operating_system/).empty?'
/opt/itamae/embedded/bin/ruby -rrubygems -e 'raise "invalid Gem.ruby: #{Gem.ruby.inspect}" unless Gem.ruby == "/opt/itamae/embedded/bin/ruby"'
/opt/itamae/embedded/bin/ruby -rrubygems -e 'pp bindir: Gem.bindir, default_bindir: Gem.default_bindir, dir: Gem.dir, default_dir: Gem.default_dir'

/opt/itamae/embedded/bin/gem env
/opt/itamae/embedded/bin/gem install --no-doc --local --ignore-dependencies vendor/cache/*.gem
/opt/itamae/embedded/bin/bundle check

ls /opt/itamae/embedded/bin
/opt/itamae/bin/itamae help

mkdir -p ${ITAMAE_DESTDIR}/usr/bin
ln -s ../../opt/itamae/bin/itamae ${ITAMAE_DESTDIR}/usr/bin/itamae
