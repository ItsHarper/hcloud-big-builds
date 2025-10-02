use ../../util/cli-constants.nu *
use ($INTERNAL_COMMAND_PATH)
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *

export def main [
	--full
	--include-non-x86
	additionalFields: list<string> = []
]: nothing -> table {
	set-up-hcloud-context

	let fullList: table = (
		hcloud server-type list --output json
		| from json
		| default []
	)

	if $full {
		$fullList
	} else {

		let friendlyList = (
			$fullList
			| where $include_non_x86 or $it.architecture == "x86"
			# | sort-by cpu_type
			| each { internal make-friendly vm-type $VM_LOCATION $additionalFields }
			| sort-by --reverse ([$CURRENCY_PER_HOUR] | into cell-path)
			| sort-by --reverse memory
			| sort-by --reverse cpu_type
		)

		if $include_non_x86 {
			$friendlyList
			| sort-by architecture # Always sort by architecture last, there is no more important field
		} else {
			$friendlyList
			| reject architecture
		}
	}
}
