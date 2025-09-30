use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_COMMANDS_DIR)/vm/verify-active.nu

# Accepts sessionId as either input or argument
# (the argument takes priority if both are provided)
export def main [sessionId?: string]: oneof<string, nothing> -> nothing {
	let sessionIdFromInput = $in
	let sessionId: string = $sessionId | default $sessionIdFromInput
	if $sessionId == null { error make { msg: "You must provide a session ID" } }

	verify-active $sessionId
	ssh-into-session-vm $sessionId
}
