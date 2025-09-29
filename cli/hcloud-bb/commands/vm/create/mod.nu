use ../../../util/cli-constants.nu *
use ../../../util/hcloud-context-management.nu *
use ../../../util/hcloud-wrapper.nu *
use ../../../util/state.nu *

const SCRIPT_DIR = path self .

# Accepts sessionId as input and passes it through as output
export def main []: string -> string {
	let sessionId = $in
	set-up-hcloud-context

	let session = get-session $sessionId
	let volumeDevPath = $session.volumeDevPath
	let resourcesName = $session.resourcesName
	let cloudConfig: string = (
		open --raw ($SCRIPT_DIR)/cloud-init.tmpl.yml
		| str replace --all "{{{buildVolumeDevicePath}}}" $volumeDevPath
		| str replace --all "{{{buildVolumeMountpoint}}}" $BUILD_DIR_MOUNTPOINT
		| str replace --all "{{{buildVolumeFs}}}" $VOLUME_FS
		| str replace --all "{{{username}}}" $VM_USERNAME
	)

	if $cloudConfig =~ "{{" { # Intentionally has just two braces for broader mistake detection
		print "cloud-init config (contains at least one variable that was not replaced):"
		print $cloudConfig
		error make { msg: "At least one variable was not replaced in cloud-init config (printed in full above)" }
	}

	print "Creating VM"
	let vmInfo = (
		$cloudConfig
		| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --type $VM_TYPE --image $VM_IMAGE --location $VM_LOCATION --output "json"
		| from json
	)

	$sessionId
}

# # For build commands:
# TODO(Harper): Use rsync to install scripts on the VM
# try {
# 	print "Initializing build environment"

# 	# software-properties-common is needed for add-apt-repository
# 	# apt-get -y install software-properties-common
# 	# add-apt-repository --component contrib

# 	# TODO(Harper): Run build environment initialization without capturing output
# } catch {|e|
# 	print -e "Failed to initialize build environment:"
# 	print -e $e.rendered
# 	error make { msg: "Session was not started (build setup step failed). Make sure to destroy the volume after investigating." }
# }

# try {
# 	print $"Successfully started session ($sessionId)"
# 	print "Running first build"
# 	# TODO(Harper): Run build without capturing output
# 	print "First build succeeded"
# } catch {|e|
# 	print -e "First build failed:"
# 	print -e $e.rendered
# 	print  "\nSession was successfully created and is valid despite build failure"
# }
