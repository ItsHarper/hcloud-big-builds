use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/vm

export def main [--preserve-on-exit, --no-preserve-on-exit, sessionId?: string]: nothing -> nothing {
	let session = get-session $sessionId
	let sessionId: string = $session.id

	if $preserve_on_exit and $no_preserve_on_exit {
		error make { msg: "--preserve-on-exit and --no-preserve-on-exit were both specified" }
	}

	vm start $sessionId

	$session.type.outputsToDownload
	| each {
		let outputToDownload: record<vmRelativePath: string, localRelativePath: string> = $in
		print $"\nDownloading ($outputToDownload.vmRelativePath)"
		let vmOutputPath = ($BUILD_ROOT_VM_DIR)/($outputToDownload.vmRelativePath)
		let localOutputPath = ($CLI_OUT_DIR)/($outputToDownload.localRelativePath)
		rsync-from-session-vm $vmOutputPath $localOutputPath $session.id
	}
	| ignore

	print $"Marking session as ($SESSION_STATUS_READY)"
	update-session-status $sessionId $SESSION_STATUS_READY
	prune
	null
}
