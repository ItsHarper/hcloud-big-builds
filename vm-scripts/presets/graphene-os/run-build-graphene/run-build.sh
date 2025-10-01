#!/bin/bash
set -eo pipefail

cd /mnt/build-root
source build/envsetup.sh
lunch "$BUILD_TARGET-$BUILD_VARIANT"
m
