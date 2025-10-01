use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/vm

export def main [sessionId?: string]: nothing -> string {
	let sessionId: string = (get-session $sessionId).id

	vm start $sessionId true
	vm sync-scripts $sessionId

	print "Running vm-run-build.nu script on VM"
	ssh-into-session-vm --command $"($RUN_NUSHELL_SCRIPT_VM_PATH) vm-run-build.nu" $sessionId

	$sessionId
}
