#!/bin/bash
set -euo pipefail

cd /mnt/build-root
source build/envsetup.sh
lunch "$BUILD_TARGET-$BUILD_VARIANT"
adevtool generate-all -d $BUILD_TARGET
