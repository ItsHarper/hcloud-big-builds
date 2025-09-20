#!/bin/bash
set -euo pipefail

# Intended to be run on a Debian 12 (bookworm) Compute Engine VM

NU_VERSION="0.107.0"

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
# TODO(Harper): Look for "Metadata-Flavor: Google"
curl metadata.google.internal -i

wget "https://github.com/nushell/nushell/releases/download/$NU_VERSION/nu-$NU_VERSION-x86_64-unknown-linux-gnu.tar.gz"

echo "init.sh complete"
