use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/prune.nu

export def main [
	--force # Shut down and delete right away (don't wait until it's about to be billed again)
	--skip-prune sessionId?: string
]: nothing -> nothing {
	let session = (get-session $sessionId)
	let sessionId = $session.id

	print "Marking session as READY"
	update-session-status $sessionId $SESSION_STATUS_READY

	if $force {
		# TODO(Harper): Check if VM is running using `cloud server describe`
		print "Commanding VM to shut down cleanly"
		hcloud server shutdown --wait-timeout 60s --quiet $session.resourcesName

		print "Deleting VM"
		hcloud server delete $session.resourcesName
	}

	if not $skip_prune and not $force {
		print "Running `prune`"
		prune
	}
}
