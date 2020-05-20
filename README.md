# itamae-package: itamae releases in *.deb

Itamae debian packages. Successor of itamae-kitchen/omnibus-itamae.

## Build process

1. `prepare.sh`: Download ruby tarball and gems
2. `build.sh`: Build source and binary package
   - Build Container
     - `in-container.sh`
       - `src/prepare.sh`
       - `src/build.sh`
         - `src/build-ruby.sh`
         - `src/install-itamae.sh`
   - Test Container
     - `in-container-test.sh`
3. `port.rb`: Build binary package from the built source package in foreign architecture (arm64)

## RPM?

Help wanted for RPM!
