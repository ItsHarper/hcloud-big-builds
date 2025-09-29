use ../../../util/cli-constants.nu *
use ../../../util/hcloud-context-management.nu *
use ../../../util/hcloud-wrapper.nu *
use ../../../util/state.nu *

# TODO(Harper): Set up pruning system
#
# Instead of performing any cleanup here, merely update the state of the session (before starting to make actual changes). Throw if that fails.
#
# The session tracking system will be responsible for creating session IDs, so that collisions can be guaranteed not to occur.
#
# `prune` command operates based on the state of the sessions:
# * starting (keep volume and VM)
# * initializingBuildEnvironment (keep volume and VM)
# * building (keep volume and VM)
# * ready (keep volume only)
# * buildEnvironmentInitializationFailure (keep volume)
# * investigatingBuildEnvironmentInitializationFailure (keep volume and VM)
# * destroyed (keep nothing)
#
# Build errors result in the `ready` state, build environment initialization errors result in the
# `buildEnvironmentInitializationFailure` state, and all other errors result in the `destroyed` state
#
# VMs are not deleted until the hour that has been paid for has almost ended (run
# `server describe` and examine the `created` field)

# TODO(Harper): Set up independent monitoring for pruning system
#

const SCRIPT_DIR = path self .

export def main []: nothing -> string {
	set-up-hcloud-context

	let sessionId = random chars --length 7
	let resourcesName = ($RESOURCES_NAME_PREFIX)-($sessionId)

	# TODO(Harper): Determine whether the hcloud docs actually mean "GB" or if they really mean "GiB"
	print "Creating volume"
	let volumeInfo: record = (
		hcloud volume create --name $resourcesName --size $VOLUME_SIZE_GiB --format $VOLUME_FS --location $VM_LOCATION --output "json"
		| from json
	)

	# TODO(Harper): Reserve and store IP address

	save-session $sessionId $resourcesName $volumeInfo.volume.linux_device

	print $"Created session ($sessionId)"

	$sessionId
}

# For pruning system:
# print -e "ERROR: Failed to destroy VM. You are leaking money."
