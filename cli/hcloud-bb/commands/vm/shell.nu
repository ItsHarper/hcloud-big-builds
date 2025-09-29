use ../../util/cli-constants.nu *
use ../../util/ssh.nu *
use ../../util/state.nu *

# Accepts sessionId as either input or argument
# (the argument takes priority if both are provided)
export def main [sessionId?: string]: oneof<string, nothing> -> nothing {
	let sessionIdFromInput = $in
	let sessionId: string = $sessionId | default $sessionIdFromInput
	ssh-into-session-vm $sessionId
}
