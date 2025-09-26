use ../util/hcloud-bb-constants.nu *
use ../util/hcloud-context-management.nu *
use ../util/hcloud-wrapper.nu *

# TODO(Harper): Check which resources need to be kept
export def main []: nothing -> nothing {
	set-up-hcloud-context

	let vms: oneof<table, nothing> = (
		hcloud server list --output json
		| from json
	)
	let volumes: oneof<table, nothing> = (
		hcloud volume list --output json
		| from json
	)

	if $vms != null {
		$vms
		| each {|vm|
			if $vm.status == "running" {
				print $"Powering off VM ($vm.name)"
				hcloud server poweroff $vm.id
			}

			print $"Deleting VM ($vm.name)"
			hcloud server delete $vm.id
		}
	}

	if $volumes != null {
		$volumes
		| each {|volume|
			print $"Deleting volume ($volume.name)"
			hcloud volume delete $volume.id
		}
	}

	null
}
