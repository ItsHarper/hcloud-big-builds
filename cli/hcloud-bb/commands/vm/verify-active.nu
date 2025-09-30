use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

export def main [sessionId: string]: nothing -> nothing {
	let session = (get-session $sessionId)

	if $session.status != $SESSION_STATUS_ACTIVE {
		error make { msg: "The specified session is not active. Run `hcloud-bb vm start` first." }
	}

	print "Verifying that VM is running"
	list vms
	| where name == $session.resourcesName
	| iter only
	| get status
	| if $in != running { error make { msg: "VM is not actually running" } }

	wait-for-vm-ping $session.ipv4Address
}

def wait-for-vm-ping [ipAddress: string]: nothing -> nothing {
	let startTime = date now
	let timeoutDuration = 2min

	print "Connecting to VM"
	mut pingSucceeded = ping $ipAddress

	if not $pingSucceeded {
		print "Waiting for VM to respond to our pings"
	}

	while ((not $pingSucceeded) and ((date now) - $startTime) < $timeoutDuration) {
		sleep 200ms
		$pingSucceeded = ping $ipAddress
	}

	if $pingSucceeded {
		print $"VM responded after (((date now) - $startTime) | format duration sec)"
	} else {
		error make { msg: $"Timed out after ($timeoutDuration) of waiting for VM to respond to our pings" }
	}
}

def ping [ipAddress: string]: nothing -> bool {
	^ping -c 1 $ipAddress
	| complete
	| $in.exit_code == 0
}
