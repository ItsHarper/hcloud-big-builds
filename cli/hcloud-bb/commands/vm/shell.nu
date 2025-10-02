use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_COMMANDS_DIR)/vm/start.nu
use ($CLI_COMMANDS_DIR)/vm/sync-scripts.nu
use ($CLI_COMMANDS_DIR)/vm/verify-active.nu

# TODO(Harper): Move to session command
# TODO(Harper): After exit, ask if user would like to stop the VM
export def main [
	--sync-scripts
	sessionId?: string
]: nothing -> nothing {
	let sessionId: string = (get-session $sessionId).id

	start $sessionId
	verify-active $sessionId
	print ""
	if $sync_scripts {
		sync-scripts $sessionId
	}
	ssh-into-session-vm $sessionId
}
