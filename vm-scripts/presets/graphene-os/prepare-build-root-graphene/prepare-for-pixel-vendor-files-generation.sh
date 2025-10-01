#!/bin/bash
set -euo pipefail

cd /mnt/build-root

# yarnpkg is the name of the Debian package for yarn
yarnpkg --cwd install vendor/adevtool/
source build/envsetup.sh
lunch sdk_phone64_x86_64-cur-user
m arsclib
