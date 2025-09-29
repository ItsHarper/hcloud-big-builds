use ../util/cli-constants.nu *
use ../util/hcloud-context-management.nu *
use ../util/hcloud-wrapper.nu *
use ../util/state.nu *

# TODO(Harper): Check which resources need to be kept
# TODO(Harper): Prune known_hosts for deleted sessions (do not clear unilaterally)
export def main []: nothing -> nothing {
	set-up-hcloud-context

	let vms: table = (
		hcloud server list --output json
		| from json
		| default []
	)
	let volumes: table = (
		hcloud volume list --output json
		| from json
		| default []
	)
	let primaryIps: table = (
		hcloud primary-ip list --output json
		| from json
		| default []
	)

	print "VMs to delete:"
	print (
		$vms
		| update created {|vm| $vm.created | into datetime }
		| select name id status volumes created
		| table --expand
	)
	print "Volumes to delete:"
	print (
		$volumes
		| update created {|volume| $volume.created | into datetime }
		| select name id status server size format created
		| table --expand
	)
	print "Primary IP addresses to delete:"
	print (
		$primaryIps
		| update created {|ip| $ip.created | into datetime }
		| where auto_delete == true
		| select name ip id type assignee_id created
		| table --expand
	)

	$vms
	| each {|vm|
		if $vm.status == "running" {
			print $"Powering off VM ($vm.name)"
			hcloud server poweroff $vm.id
		}

		print $"Deleting VM ($vm.name)"
		hcloud server delete $vm.id
	}

	$volumes
	| each {|volume|
		print $"Deleting volume ($volume.name)"
		hcloud volume delete $volume.id
	}

	$primaryIps
	| each {|ip|
		print $"Deleting primary IP address ($ip.name) \(($ip.ip)\)"
		hcloud primary-ip delete $ip.id
	}

	clear-sessions

	null
}
