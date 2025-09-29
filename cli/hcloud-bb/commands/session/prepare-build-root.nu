use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/vm

# Accepts sessionId as either input or argument and passes it through as output
# (the argument takes priority if both are provided)
export def main [sessionId?: string]: oneof<nothing, string> -> string {
	let sessionIdFromInput = $in
	let sessionId: string = $sessionId | default $sessionIdFromInput
	if $sessionId == null { error make { msg: "You must provide a session ID" } }

	vm start $sessionId
	vm sync-scripts $sessionId

	print "Running vm-prepare-build-root.nu script on VM"
	ssh-into-session-vm --command $"($RUN_NUSHELL_SCRIPT_VM_PATH) vm-prepare-build-root.nu" $sessionId

	$sessionId
}
