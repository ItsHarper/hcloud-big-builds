use ../../../util/cli-constants.nu *
use ($INTERNAL_COMMAND_PATH)/make-friendly/vm-type.nu

export def main []: record -> record {
	let vm = $in
	let locationInfo: record = $vm.datacenter.location

	$vm
	| select name status created server_type volumes id
	| update created {|vm|
		let creationTime = $vm.created | into datetime

		((date now) - $creationTime)
		# Get rid of sub-minute precision
		| format duration min
		| parse '{minutes} min'
		| iter only
		| get minutes
		| into float
		| math round
		| into duration -u min
	}
	| rename --column { created: "running" }
	| update server_type {|vm|
		$vm.server_type
		| vm-type $locationInfo.name
	}
	| insert location $locationInfo.description
	| move location --before id
}
