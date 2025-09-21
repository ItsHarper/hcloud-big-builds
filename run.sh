#!/bin/bash
set -euo pipefail

# Intended to be run on a Debian 12 (bookworm) Compute Engine VM

NU_VERSION="0.107.0"
NU_ARCHIVES_DIR="$HOME/nushell-bin-archives"
NU_ARCHIVE_FILENAME="nu-$NU_VERSION-x86_64-unknown-linux-gnu.tar.gz"
NU_ARCHIVE_PATH="$NU_ARCHIVES_DIR/$NU_ARCHIVE_FILENAME"
NU_BIN_DIR="$HOME/nushell-bin"
NU_PATH="$NU_BIN_DIR/nu"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
curl metadata.google.internal -i

# Download nushell if necessary
if [[ ! -f $NU_PATH ]] || [[ "$($NU_PATH --version)" != "$NU_VERSION" ]]; then
	echo "Downloading nushell"
	mkdir -p "$NU_ARCHIVES_DIR"
	curl --location https://github.com/nushell/nushell/releases/download/"$NU_VERSION"/"$NU_ARCHIVE_FILENAME" > "$NU_ARCHIVE_PATH"

	echo "Extracting nushell"
	mkdir -p "$NU_BIN_DIR"
	tar xvzf "$NU_ARCHIVE_PATH" --strip-components=1 --directory "$NU_BIN_DIR"
fi

echo "Running the main script using nushell"
"$NU_BIN_DIR/nu" "$SCRIPT_DIR"/run.nu
