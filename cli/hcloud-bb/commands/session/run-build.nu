use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/vm

export def main [
	--ignore-minimium-ram
	sessionId?: string
]: nothing -> nothing {
	let sessionId: string = (get-session $sessionId).id
	let vmConstraint = {|vm|
		(
			$vm.cpu_type == "dedicated" and
			($ignore_minimium_ram or $vm.memory >= $VM_MIN_RAM_GiB_GRAPHENE)
		)
	}

	vm start $sessionId $vmConstraint

	print "Running vm-run-build.nu script on VM"
	try {
		ssh-into-session-vm --command $"($RUN_NUSHELL_SCRIPT_VM_PATH) vm-run-build.nu" $sessionId
		print $"Marking session as ($SESSION_STATUS_READY)"
		update-session-status $sessionId $SESSION_STATUS_READY
	} catch {|e|
		print -e $e.rendered
		print $"Marking session as ($SESSION_STATUS_READY)"
		update-session-status $sessionId $SESSION_STATUS_READY
		error make { msg: "Build failed" }
	}
}
