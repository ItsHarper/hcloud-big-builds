use ../../../../common/common-constants.nu *
use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *

# Accepts sessionId as either input or argument and passes it through as output
# (the argument takes priority if both are provided)
export def main [sessionId?: string]: oneof<nothing, string> -> string {
	let sessionIdFromInput = $in
	let sessionId: string = $sessionId | default $sessionIdFromInput
	if $sessionId == null { error make { msg: "You must provide a session ID" } }

	let session = (get-session $sessionId)
	wait-for-vm-ping $session.ipv4Address

	print "Syncing scripts to VM"
	rsync-to-session-vm $TOP_LEVEL_COMMON_DIR $HCLOUD_BB_VM_DIR $sessionId
	rsync-to-session-vm $VM_SCRIPTS_DIR $HCLOUD_BB_VM_DIR $sessionId

	$sessionId
}
