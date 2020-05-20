#!/bin/bash -xe

dist=$1

mkdir -p tmp/build-$$
mkdir -p tmp/build-$$/out
tar cf ./tmp/build-$$/source.tar -C src .

cp in-container.sh tmp/build-$$/entrypoint.sh
cp in-container-test.sh tmp/build-$$/test-entrypoint.sh

docker build --build-arg BUILDDATE=$(date +%Y%m%d) -t itamae-package-${dist} -f docker/Dockerfile.${dist} ./docker
docker run --rm \
  -e BUILDBOT_UID=$(id -u) \
  -e BUILDBOT_GID=$(id -g) \
  -v $PWD/tmp/build-$$:/work \
  itamae-package-${dist} /work/entrypoint.sh

docker run --rm \
  -v $PWD/tmp/build-$$:/work:ro \
  itamae-package-${dist} /work/test-entrypoint.sh

mkdir -p out
mv ./tmp/build-$$/out/* ./out/


