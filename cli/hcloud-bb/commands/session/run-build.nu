use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/prune.nu
use ($CLI_COMMANDS_DIR)/vm

export def main [
	--ignore-minimium-ram
	sessionId?: string
]: nothing -> nothing {
	let session = get-session $sessionId
	let sessionId: string = $session.id
	let vmTypeConstraint = {|vm|
		(
			$vm.cpu_type == "dedicated" and
			$vm.architecture == "x86" and
			($ignore_minimium_ram or $vm.memory >= $session.type.minRamGiB)
		)
	}

	vm start $sessionId $vmTypeConstraint

	try {
		print "Running vm-run-build.nu script on VM"
		ssh-into-session-vm --command $"($RUN_NUSHELL_SCRIPT_VM_PATH) vm-run-build.nu ($session.type.id)" $sessionId

		download-outputs $session

		print $"Marking session as ($SESSION_STATUS_READY)"
		update-session-status $sessionId $SESSION_STATUS_READY
		prune
	} catch {|e|
		print -e $e.rendered
		print $"Marking session as ($SESSION_STATUS_READY)"
		update-session-status $sessionId $SESSION_STATUS_READY
		prune
		error make { msg: "Build failed" }
	}
}

export def download-outputs [session: record]: nothing -> nothing {
	$session.type.outputsToDownload
	| each {
		let outputToDownload: record<vmRelativePath: string, localRelativePath: string> = $in
		print $"\nDownloading ($outputToDownload.vmRelativePath)"
		let vmOutputPath = ($BUILD_ROOT_VM_DIR)/($outputToDownload.vmRelativePath)
		let localOutputPath = ($CLI_OUT_DIR)/($outputToDownload.localRelativePath)
		rsync-from-session-vm $vmOutputPath $localOutputPath $session.id
	}
	| ignore
}
