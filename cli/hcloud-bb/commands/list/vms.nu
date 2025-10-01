use ../../util/cli-constants.nu *
use ($INTERNAL_COMMAND_PATH)
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *

export def main [--full]: nothing -> table {
	set-up-hcloud-context

	let fullList: table = (
		hcloud server list --output json
		| from json
		| default []
		| update created {|vm| $vm.created | into datetime }
	)

	if $full {
		$fullList
	} else {
		$fullList
		| each { internal make-friendly vm }
	}
}
