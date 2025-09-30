use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *

export def main [sessionId: string]: nothing -> string {
	let session = (get-session $sessionId)
	wait-for-vm-ping $session.ipv4Address

	print "Syncing scripts to VM"
	rsync-to-session-vm $TOP_LEVEL_COMMON_DIR $HCLOUD_BB_VM_DIR $sessionId
	rsync-to-session-vm $VM_SCRIPTS_DIR $HCLOUD_BB_VM_DIR $sessionId

	$sessionId
}
