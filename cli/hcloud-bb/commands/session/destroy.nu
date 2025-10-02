use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/prune.nu
use ($CLI_COMMANDS_DIR)/vm/stop.nu

export def main [sessionId?: string]: nothing -> nothing {
	let sessionId: string = (get-session $sessionId) | get id

	# Don't bother with a clean shutdown, we are throwing away the whole thing

	print "Deleting session state"
	delete-session $sessionId

	print "Running `prune`"
	prune
}
