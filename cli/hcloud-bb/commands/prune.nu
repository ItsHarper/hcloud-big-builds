use ../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

# TODO(Harper): Check which resources need to be kept
# TODO(Harper): Prune known_hosts for deleted sessions (do not clear unilaterally)
export def main []: nothing -> nothing {
	set-up-hcloud-context

	let vms = list vms
	let volumes: table = (
		hcloud volume list --output json
		| from json
		| default []
		| update created {|volume| $volume.created | into datetime }
	)
	let primaryIps: table = (
		hcloud primary-ip list --output json
		| from json
		| default []
		| update created {|ip| $ip.created | into datetime }
		# auto_deleted IPs don't need manual cleanup
		| where auto_delete == false
	)

	print "VMs to delete:"
	print (
		$vms
		| list vms make-friendly
		| table --expand
	)
	print "Volumes to delete:"
	print (
		$volumes
		| select name id status server size format created
		| table --expand
	)
	print "Primary IP addresses to delete:"
	print (
		$primaryIps
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

# TODO(Harper): Make pruning system more advanced
#
# `prune` command operates based on the status of the sessions:
# * starting (keep volume and VM)
# * initializingBuildEnvironment (keep volume and VM)
# * building (keep volume and VM)
# * ready (keep volume only)
# * buildEnvironmentInitializationFailure (keep volume)
# * investigatingBuildEnvironmentInitializationFailure (keep volume and VM)
# * destroyed (keep nothing)
#
# Build errors result in the `ready` status, build environment initialization errors result in the
# `buildEnvironmentInitializationFailure` status, and all other errors result in the `destroyed` status
#
# More granular statuses like this will:
# * Allow for imperfect error handling
#   * For example, if a VM fails to be created and the state isn't updated accordingly,
#     we can detect that a session has been in the `starting` state for way too long
#     and destroy it
# * Allow us to accurately update the session status by looking at the VM list
#   * For example, if a session has been in the `building` status for several minutes,
#     but does not have a VM running, we can safely downgrade it to the "ready" status
#
# Ensure that the state is always updated BEFORE an operation begins
#
# VMs are not deleted until the hour that has been paid for has almost ended (run
# `server describe` and examine the `created` field)

# TODO(Harper): Set up independent monitoring for pruning system

# TODO(Harper): Make the session tracking system responsible for creating session IDs, so that collisions can be guaranteed not to occur.
