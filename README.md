# itamae-package: itamae releases in *.deb

Itamae software packages. Successor of itamae-kitchen/omnibus-itamae.

## Build

### Prepare sources

Download required external dependencies (Ruby source tarball and itamae gems)

```
./prepare.sh
```

### Build package

```
# single distro
./build.sh DISTRO
# all supported distros
./build-all.sh
```

where `DISTRO` is `./docker/Dockerfile.${DISTRO}`, e.g. `bionic`, `focal`, `buster`

package files will be saved to `./out/*`

### Port package onto arm64

## Details

### Custom rubygems

Gem additionally installed with `/opt/itamae/embedded/bin/gem` will be installed under `/var/lib/itamae/gems`.
Executable files will be installed at `/var/lib/itamae/bin`.

These gems are preserved between upgrades, unless an upgrade contains a change in Ruby ABI (major/minor upgrade).

### Build process

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

## Release Process



## RPM?

Help wanted for RPM!
