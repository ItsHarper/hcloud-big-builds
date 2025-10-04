use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_COMMANDS_DIR)/vm/start.nu

# TODO(Harper): Move to session command
# TODO(Harper): After exit, ask if user would like to shut down the VM
export def main [
	sessionId?: string
]: nothing -> nothing {
	let sessionId: string = (get-session $sessionId).id

	start $sessionId
	print ""
	ssh-into-session-vm  $sessionId
}
