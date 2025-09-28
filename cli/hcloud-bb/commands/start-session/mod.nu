use ../../util/cli-constants.nu *
use ../../util/hcloud-context-management.nu *
use ../../util/hcloud-wrapper.nu *

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

	try {
		# TODO(Harper): Determine whether the hcloud docs actually mean "GB" or if they really mean "GiB"
		print "Creating volume"
		let volumeInfo: record = (
			hcloud volume create --name $resourcesName --size $VOLUME_SIZE_GiB --format $VOLUME_FS --location $VM_LOCATION --output "json"
			| from json
		)

		let volumeLinuxDevice = $volumeInfo.volume.linux_device
		let cloudConfig: string = (
			open --raw ($SCRIPT_DIR)/cloud-init.tmpl.yml
			| str replace "{{{buildVolumeDevicePath}}}" $volumeLinuxDevice
			| str replace "{{{buildVolumeMountpoint}}}" $BUILD_DIR_MOUNTPOINT
			| str replace "{{{buildVolumeFs}}}" $VOLUME_FS
			| str replace "{{{username}}}" $VM_USERNAME
		)

		print "Creating VM"
		let vmInfo = (
			$cloudConfig
			| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --type $VM_TYPE --image $VM_IMAGE --location $VM_LOCATION --output "json"
			| from json
		)

		# TODO(Harper): Use rsync to install scripts on the VM

		null
	} catch {|e|
		print -e "Failed to set up VM:"
		print -e $e.rendered
		error make { msg: "Session was not started (VM setup failed). This is not a bug in the build or build environment initialization scripts." }
	}

	try {
		print "Initializing build environment"

		# software-properties-common is needed for add-apt-repository
		# apt-get -y install software-properties-common
		# add-apt-repository --component contrib

		# TODO(Harper): Run build environment initialization without capturing output
	} catch {|e|
		print -e "Failed to initialize build environment:"
		print -e $e.rendered
		error make { msg: "Session was not started (build setup step failed). Make sure to destroy the volume after investigating." }
	}

	try {
		print $"Successfully started session ($sessionId)"
		print "Running first build"
		# TODO(Harper): Run build without capturing output
		print "First build succeeded"
	} catch {|e|
		print -e "First build failed:"
		print -e $e.rendered
		print  "\nSession was successfully created and is valid despite build failure"
	}

	$sessionId
}

# For pruning system:
# print -e "ERROR: Failed to destroy VM. You are leaking money."
