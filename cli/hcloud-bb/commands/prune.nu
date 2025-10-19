use ../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

const SYNTHETIC_SESSION_STATUS_ZOMBIE = "ZOMBIE"

export def main []: nothing -> record {
	set-up-hcloud-context
	let sessions = list sessions

	# Check for VMs that are shut down
	# A shut-down VM costs just as much as a running one, so we update the status to indicate that we don't need the VM
	list vms | each {|vm|
		let session: oneof<record, nothing> = $sessions | where resourcesName == $vm.name | get --optional 0
		# VMs without sessions are zombies and will get destroyed; we can ignore those
		if $session != null and $vm.status == "off" and $session.status != $SESSION_STATUS_READY {
			print $"Marking session ($session.id) as READY \(its VM is shut down\)"
			update-session-status $session.id $SESSION_STATUS_READY
		}
	}

	# Refresh sessions to reflect any changes made in the previous step
	let sessions = list sessions

	let vms = list vms | add-session-status-column $sessions
	let vmDeletionFilter = {|vm|
		(
			# Delete zombies right away (the user has asserted that they're done)
			$vm.sessionStatus == $SYNTHETIC_SESSION_STATUS_ZOMBIE
			or (
				# Delete non-zombies right before they get billed for another hour
				$vm.sessionStatus != $SESSION_STATUS_ACTIVE and
				($vm.running mod 1hr) > 53min
			)
		)
	}
	let vmDeleter = {|vm|
		if $vm.status == "running" {
			hcloud server shutdown --wait-timeout $VM_SHUTDOWN_TIMEOUT $vm.id
		}
		hcloud server delete $vm.id
	}
	let vmResults = prune-resouce-type "VM" $vms $vmDeletionFilter $vmDeleter

	let volumes: table = (
		hcloud volume list --output json
		| from json
		| default []
		| update created {|volume| $volume.created | into datetime }
		| add-session-status-column $sessions
		| select name sessionStatus status size format created id
	)
	let volumeDeletionFilter = {|volume|
		$volume.sessionStatus == $SYNTHETIC_SESSION_STATUS_ZOMBIE
	}
	let volumeDeleter = {|volume|
		hcloud volume delete $volume.id
	}
	let volumeResults = prune-resouce-type "volume" $volumes $volumeDeletionFilter $volumeDeleter

	let primaryIps: table = (
		hcloud primary-ip list --output json
		| from json
		| default []
		| update created {|ip| $ip.created | into datetime }
		| add-session-status-column $sessions
		# auto-deleted IPs aren't relevant
		| where auto_delete == false
		| select name sessionStatus ip type created id
	)
	let primaryIpDeletionFilter = {|primaryIp|
		$primaryIp.sessionStatus == $SYNTHETIC_SESSION_STATUS_ZOMBIE
	}
	let primaryIpDeleter = {|primaryIp|
		hcloud primary-ip delete $primaryIp.id
	}
	let primaryIpResults = prune-resouce-type "primary IP" $primaryIps $primaryIpDeletionFilter $primaryIpDeleter

	let result = {
		timestamp: (date now)
		vms: $vmResults
		volumes: $volumeResults
		primaryIps: $primaryIpResults
	}

	touch $PRUNE_LOG_PATH

	let pruneLog: table = try {
		let parsedContents = open $PRUNE_LOG_PATH
		let parsedType = $parsedContents | describe
		if $parsedType starts-with "list" or $parsedType starts-with "table" {
			$parsedContents
		} else {
			[]
		}
	} catch {
		[]
	}

	$pruneLog
	| append $result
	| collect
	| save -f $PRUNE_LOG_PATH

	$result
	| reject timestamp
}

export def log []: nothing -> nothing {
	open $PRUNE_LOG_PATH
	| default []
	| each {|logEntry|
		print $"\n($logEntry.timestamp | into datetime)"
		print ($logEntry | reject timestamp | table --expand)
	}
	| ignore
}

def prune-resouce-type [resourceTypeName: string, resources: table, deletionFilter: closure, deleter: closure]: nothing -> record {
	let toDelete = (
		$resources | where $deletionFilter
	)
	let toKeep = (
		$resources | where not (do $deletionFilter $it)
	)

	$toDelete
	| each {|resource|
		print $"Deleting ($resourceTypeName) ($resource.name)"
		do $deleter $resource
	}

	{
		kept: $toKeep
		deleted: $toDelete
	}
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
# * shellOpen (keep volume and VM) (needs additional safeguards)
# * ready (keep volume only)
# * destroyed (keep nothing)
#
# Rather than having a special state for a build initialization failure,
# build initialization should be idempotent, even if that means that it nukes and paves the build root.
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
