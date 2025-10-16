#!/bin/bash
set -euo pipefail

NU_VERSION="0.107.0"
NU_ARCHIVES_DIR="$HOME/nushell-bin-archives"
NU_ARCHIVE_FILENAME="nu-$NU_VERSION-x86_64-unknown-linux-gnu.tar.gz"
NU_ARCHIVE_PATH="$NU_ARCHIVES_DIR/$NU_ARCHIVE_FILENAME"
NU_BIN_DIR="$HOME/nushell-bin"
NU_PATH="$NU_BIN_DIR/nu"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Download nushell if necessary
if [[ ! -f $NU_PATH ]] || [[ "$($NU_PATH --version)" != "$NU_VERSION" ]]; then
	echo "Downloading nushell"
	mkdir -p "$NU_ARCHIVES_DIR"
	curl --location https://github.com/nushell/nushell/releases/download/"$NU_VERSION"/"$NU_ARCHIVE_FILENAME" > "$NU_ARCHIVE_PATH"

	echo "Extracting nushell"
	mkdir -p "$NU_BIN_DIR"
	tar xvzf "$NU_ARCHIVE_PATH" --strip-components=1 --directory "$NU_BIN_DIR"
fi

echo "Executing: $@"
"$NU_BIN_DIR/nu" "$SCRIPT_DIR/$@"
