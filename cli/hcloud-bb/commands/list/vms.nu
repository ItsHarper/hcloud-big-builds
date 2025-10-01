use std-rfc/iter
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
	each {|vm|
		let location: record = $vm.datacenter.location
		let hourlyPrice = (
			$vm.server_type.prices
			| where location == $location.name
			| iter only
			| get price_hourly
			| get net
			| into float
			# | $"$($in) / hr"
			| $"$($in)"
		)

		$vm
		| select name id status server_type volumes created
		| update server_type {|vm|
			$vm.server_type
			| select name cpu_type cores memory
			| insert "price/hr" $hourlyPrice
		}
		| insert location $location.description
		| move location --before created
	}
}
