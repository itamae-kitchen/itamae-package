# itamae-package: itamae releases in *.deb

Itamae debian packages. Successor of itamae-kitchen/omnibus-itamae.

## Build

### For signel

## Build process

- `prepare.sh`: Download ruby tarball and gems
- `build-all.sh`:
  - `build.sh`: Build source and binary package for a single distro
    - Build Container
      - `in-container.sh`
        - `src/prepare.sh`
        - `src/build.sh`
          - `debuild` - `debian/rules`
            - `src/build-ruby.sh`
            - `src/install-itamae.sh`
    - Test Container
      - `in-container-test.sh`
- `port.rb`: Build binary package from the built source package in foreign architecture (arm64)

## RPM?

Help wanted for RPM!
