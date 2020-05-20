#!/bin/bash -xe

(
  cd ruby
  ./configure \
    --prefix=/opt/itamae/embedded \
    --enable-shared \
    --with-out-ext=tcl \
    --with-out-ext=tk \
    --with-out-ext=win32ole \
    --with-out-ext=win32api \
    --with-compress-debug-sections=no \
    --disable-install-doc

  make -j $(nproc)
  make -j $(nproc) install DESTDIR=${ITAMAE_DESTDIR}
)

ln -s "$(realpath ${ITAMAE_DESTDIR}/opt/itamae)" /opt/itamae
mkdir -p /opt/itamae/embedded/lib/ruby/vendor_ruby/rubygems/defaults
cp rubygems_os.rb /opt/itamae/embedded/lib/ruby/vendor_ruby/rubygems/defaults/operating_system.rb

