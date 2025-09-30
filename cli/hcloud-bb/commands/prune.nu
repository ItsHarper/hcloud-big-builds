use ../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

const SYNTHETIC_SESSION_STATUS_ZOMBIE = "ZOMBIE"

export def main []: nothing -> nothing {
	set-up-hcloud-context

	let sessions = list sessions
	let vms = list vms | add-session-status-column $sessions
	let volumes: table = (
		hcloud volume list --output json
		| from json
		| default []
		| update created {|volume| $volume.created | into datetime }
		| add-session-status-column $sessions
	)
	let primaryIps: table = (
		hcloud primary-ip list --output json
		| from json
		| default []
		| update created {|ip| $ip.created | into datetime }
		| add-session-status-column $sessions
		# auto-deleted IPs aren't relevant
		| where auto_delete == false
	)

	let vmsToDelete = (
		$vms
		| where sessionStatus != $SESSION_STATUS_ACTIVE
	)
	let volumesToDelete: table = (
		$volumes
		| where sessionStatus == $SYNTHETIC_SESSION_STATUS_ZOMBIE
	)
	let primaryIpsToDelete: table = (
		$primaryIps
		| where sessionStatus == $SYNTHETIC_SESSION_STATUS_ZOMBIE
	)

	print "VMs:"
	print (
		$vms
		| table --expand
	)

	print "VMs to delete:"
	print (
		$vmsToDelete
		| table --expand
	)

	print "Volumes:"
	print (
		$volumes
		| select name sessionStatus id status server size format created
		| table --expand
	)

	print "Volumes to delete:"
	print (
		$volumesToDelete
		| select name sessionStatus id status server size format created
		| table --expand
	)

	print "Primary IP addresses:"
	print (
		$primaryIps
		| select name sessionStatus ip id type assignee_id created
		| table --expand
	)

	print "Primary IP addresses to delete:"
	print (
		$primaryIpsToDelete
		| select name sessionStatus ip id type assignee_id created
		| table --expand
	)

	$vmsToDelete
	| each {|vm|
		if $vm.status == "running" {
			print $"Powering off VM ($vm.name)"
			hcloud server poweroff $vm.id
		}

		print $"Deleting VM ($vm.name)"
		hcloud server delete $vm.id
	}

	$volumesToDelete
	| each {|volume|
		print $"Deleting volume ($volume.name)"
		hcloud volume delete $volume.id
	}

	$primaryIpsToDelete
	| each {|ip|
		print $"Deleting primary IP address ($ip.name) \(($ip.ip)\)"
		hcloud primary-ip delete $ip.id
	}

	null
}

# Accepts and returns a table of resources
def add-session-status-column [sessions: table]: table<name: string> -> table<name: string, sessionStatus: string> {
	insert sessionStatus {|resource|
		$sessions
		| where resourcesName == $resource.name
		| get status
		| get --optional 0
		| default $SYNTHETIC_SESSION_STATUS_ZOMBIE
	}
	| move --after name sessionStatus
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
#   * For example, if a VM fails to be created and the status isn't updated accordingly,
#     we can detect that a session has been in the `starting` status for way too long
#     and destroy it
# * Allow us to accurately update the session status by looking at the VM list
#   * For example, if a session has been in the `building` status for several minutes,
#     but does not have a VM running, we can safely downgrade it to the "ready" status
#
# Ensure that the status is always updated BEFORE an operation begins
#
# VMs are not deleted until the hour that has been paid for has almost ended (run
# `server describe` and examine the `created` field)

# TODO(Harper): Set up independent monitoring for pruning system

# TODO(Harper): Make the session tracking system responsible for creating session IDs, so that collisions can be guaranteed not to occur.
