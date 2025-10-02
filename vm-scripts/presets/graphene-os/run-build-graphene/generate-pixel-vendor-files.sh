#!/bin/bash
set -eo pipefail

cd /mnt/build-root

# adevtool gets defined as an alias by `build/envsetup.sh`
shopt -s expand_aliases

source build/envsetup.sh
lunch sdk_phone64_x86_64-cur-user
adevtool generate-all -d $PIXEL_CODENAME
