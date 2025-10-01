use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_COMMANDS_DIR)/vm/start.nu
use ($CLI_COMMANDS_DIR)/vm/verify-active.nu

export def main [sessionId?: string]: nothing -> nothing {
	let sessionId: string = (get-session $sessionId).id

	start $sessionId false
	verify-active $sessionId
	print ""
	ssh-into-session-vm $sessionId
}
