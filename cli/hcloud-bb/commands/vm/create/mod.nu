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

	let cloudInitConfig = generate-cloud-init-config $session

	print ($cloudInitConfig | table --expand)
	print "\n\n\n"
	print ($cloudInitConfig | to yaml)

	print "Creating VM"
	let vmInfo = (
		$cloudInitConfig
		| to yaml
		| $"#cloud-config\n\n($in)"
		| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --type $VM_TYPE --image $VM_IMAGE --location $VM_LOCATION --output "json"
		| from json
	)

	$sessionId
}

def generate-cloud-init-config [session: record<volumeDevPath: string>]: nothing -> record {
	{
		users: [
			{
				name: $VM_USERNAME
				sudo: [
					# Only allow sudo to be used to run apt-get and add-apt-repository
					$"($VM_USERNAME) ALL=NOPASSWD:/usr/bin/apt-get"
					$"($VM_USERNAME) ALL=NOPASSWD:/usr/bin/add-apt-repository"
				]
			}
		]
		mounts: [
			[
				$session.volumeDevPath
				$BUILD_DIR_MOUNTPOINT
				$VOLUME_FS
				"discard,defaults"
				"0"
				"2"
			]
		]
	}
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
