use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/state.nu *

export def main []: nothing -> table {
	open (get-sessions-path)
	| values
	| reject volumeDevPath
	| update type {|session|
		$session.type.description
	}
}
