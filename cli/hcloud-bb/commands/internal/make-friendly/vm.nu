use ../../../util/cli-constants.nu *
use ($INTERNAL_COMMAND_PATH)/make-friendly/vm-type.nu

export def main []: record -> record {
	let vm = $in
	let locationInfo: record = $vm.datacenter.location

	$vm
	| select name id status server_type volumes created
	| update server_type {|vm|
		$vm.server_type
		| vm-type $locationInfo.name
	}
	| insert location $locationInfo.description
	| move location --before created
}
