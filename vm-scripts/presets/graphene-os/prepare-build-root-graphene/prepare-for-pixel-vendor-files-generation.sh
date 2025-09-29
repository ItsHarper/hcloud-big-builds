#!/bin/bash
set -euo pipefail

yarnpkg install --cwd vendor/adevtool/
source build/envsetup.sh
lunch sdk_phone64_x86_64-cur-user
m arsclib
