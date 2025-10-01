use ../../util/cli-constants.nu *
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
		| make-friendly
	}
}

def make-friendly []: table -> table {
	select name id status server_type volumes created
	| update server_type {|vm|
		$vm.server_type
		| select name cpu_type cores memory
	}
}
