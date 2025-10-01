#!/bin/bash
set -eo pipefail

cd /mnt/build-root
source build/envsetup.sh
lunch "$BUILD_TARGET-cur-$BUILD_VARIANT"
adevtool generate-all -d $BUILD_TARGET
