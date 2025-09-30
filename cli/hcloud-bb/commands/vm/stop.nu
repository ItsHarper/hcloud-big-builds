use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/prune.nu
use ($CLI_COMMANDS_DIR)/vm/verify-active.nu

export def main [--skip-prune sessionId: string]: nothing -> nothing {
	let session = (get-session $sessionId)
	let vmExpectedToBeRunning = ($session.status == $SESSION_STATUS_ACTIVE)

	if $vmExpectedToBeRunning {
		print "Commanding VM to shut down cleanly"
		hcloud server shutdown --wait=true --wait-timeout 120s --quiet $session.resourcesName
	} else {
		print "The VM should already be stopped"
	}

	print "Marking session as READY"
	update-session-status $sessionId $SESSION_STATUS_READY

	if not $skip_prune {
		print "Running `prune`"
		prune
	}
}
