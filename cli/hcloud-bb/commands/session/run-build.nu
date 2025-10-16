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
			($ignore_minimium_ram or $vm.memory >= $session.type.minRamGiB)
		)
	}

	vm start $sessionId $vmTypeConstraint

	try {
		print "Running vm-run-build.nu script on VM"
		ssh-into-session-vm --command $"($RUN_NUSHELL_SCRIPT_VM_PATH) vm-run-build.nu" $sessionId

		download-fastboot-outputs $sessionId

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

export def download-fastboot-outputs [sessionId: string]: nothing -> nothing {
	$GRAPHENE_BUILD_TARGETS
	| each {|target|
		print $"\nDownloading ($target) fastboot outputs from VM\n"

		let localTargetOutDir = ($CLI_OUT_DIR)/($target)/
		mkdir $localTargetOutDir
		let vmTargetOutDir = ($BUILD_ROOT_VM_DIR)/out/target/product/($target)
		rsync-from-session-vm ($vmTargetOutDir)/*.img $localTargetOutDir $sessionId
		rsync-from-session-vm ($vmTargetOutDir)/fastboot-info.txt $localTargetOutDir $sessionId
		rsync-from-session-vm ($vmTargetOutDir)/android-info.txt $localTargetOutDir $sessionId
	}
	| ignore
}
