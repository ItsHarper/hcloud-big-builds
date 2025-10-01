use ../../util/cli-constants.nu *
use $COMMON_CONSTANTS_PATH *
use $INTERNAL_COMMAND_PATH
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

const SCRIPT_DIR = path self .

export def main [sessionId: string, startingBuild: bool]: nothing -> string {
	set-up-hcloud-context

	try {
		let action = get-needed-action $sessionId $startingBuild

		# Make sure the status is set to ACTIVE before we actually change
		# the state of a, so that it can't get pruned
		print $"Marking session as ($SESSION_STATUS_ACTIVE)"
		update-session-status $sessionId $SESSION_STATUS_ACTIVE

		do $action
	} catch {|e|
		print -e "Failed to start VM:"
		print -e $e.rendered

		update-session-status $sessionId $SESSION_STATUS_READY
		error make { msg: $"Failed to start VM ($e.msg)" }
	}

	$sessionId
}

# Does all the needed prep work to figure out what needs to happen, without actually
# updating the state of the VM (that's the responsibility of the returned closure).
def get-needed-action [$sessionId: string, startingBuild: bool]: nothing -> closure {
	let session = get-session $sessionId
	let sessionId: string = $session.id
	let resourcesName = $session.resourcesName
	let desiredVmType: string = get-desired-vm-type $session.type $startingBuild

	print "Getting list of existing VMs"
	let existingVm: oneof<record, nothing> = (
		list vms
		| where name == $resourcesName
		| get --optional 0
	)

	if $existingVm != null {
		# We can only reuse existing VMs if they match our
		# desired type or we are NOT about to start a build
		if $existingVm.server_type.name == $desiredVmType or not $startingBuild {
			return { reuse-existing-vm $existingVm }
		}
	}

	print "Fetching VM type details"
	let vmTypeDetails = (
		hcloud server-type describe --output json $desiredVmType
		| from json
		| internal make-friendly vm-type $VM_LOCATION
	)

	if $existingVm == null {
		print "Are you sure you would like to create a VM of this type?"
	} else {
		print "Are you sure you would like to replace the existing VM with one of this type?"
	}
	print ($vmTypeDetails | table --expand)
	let confirmed = [[text result]; [Yes true] [No false]] | input list -d text | get result

	if not $confirmed {
		error make { msg: "User did not confirm VM creation" }
	}

	{ # Return closure
		if $existingVm != null {
			# It's critical that we do NOT change the session's status, so we must use `hcloud` directly

			print "Shutting down existing VM"
			hcloud server shutdown --wait=true --wait-timeout 120s --quiet $existingVm.id

			print "Deleting existing VM"
			hcloud server delete $existingVm.id
		}

		create-vm $session $desiredVmType $startingBuild
	}
}

def get-desired-vm-type [sessionType: string, startingBuild: bool]: nothing -> string {
	if $sessionType == $SESSION_TYPE_TEST_ONLY {
		$VM_TYPE_TEST_INVESTIGATE
	} else if $sessionType == $SESSION_TYPE_GRAPHENE {
		if $startingBuild {
			$VM_TYPE_BUILD_GRAPHENE
		} else {
			$VM_TYPE_TEST_INVESTIGATE
		}
	} else {
		error make { msg: $"Unrecognized session type: ($sessionType)" }
	}
}

def reuse-existing-vm [vm: record]: nothing -> nothing {
	print "Reusing existing VM:"
	print ($vm | reject id volumes | table --expand)
	let status = $vm.status
	if $status == "off" {
		print "Starting VM"
		hcloud server poweron $vm.name
	} else if $status != "running" {
		error make { msg: $"Unrecognized VM status: ($status)" }
	}
}

def create-vm [session: record, vmType: string, startingBuild: bool]: nothing -> nothing {
	let resourcesName: string = $session.resourcesName
	let volumeDevPath: string = $session.volumeDevPath
	let ipv4Address: string = $session.ipv4Address
	let vmImage = $VM_IMAGE

	print "Generating VM configuration"
	let cloudInitConfig = generate-cloud-init-config $session $vmType $vmImage

	print "Creating and starting VM"
	let vmInfo = (
		$cloudInitConfig
		| to yaml
		| $"#cloud-config\n\n($in)"
		| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --primary-ipv4 $resourcesName --type $vmType --image $vmImage --datacenter $VM_DATACENTER --quiet --output "json"
		| from json
		| get server
	)
}

def generate-cloud-init-config [session: record<id: string, volumeDevPath: string>, vmType: string, vmImage: string]: nothing -> record {
	let sessionId = $session.id
	let sshKeys = get-ssh-keys-for-vm-creation $sessionId
	{
		users: [
			{
				name: $VM_USERNAME
				shell: "/bin/bash"
				ssh_authorized_keys: $sshKeys.clientPublicKey
				sudo: [
					# Only allow sudo to be used to run apt-get and shutdown
					$"ALL=\(ALL\) NOPASSWD:/usr/bin/apt-get"
					$"ALL=\(ALL\) NOPASSWD:/usr/sbin/shutdown"
				]
			}
		]
		mounts: [
			[
				$session.volumeDevPath
				$BUILD_ROOT_VM_DIR
				$VOLUME_FS
				"discard,defaults"
				"0"
				"2"
			]
		]
		# Set up the VM's host SSH keys. These are only used to identify the VM, so even the private key is not that sensitive.
		# Actually-sensitive data does not belong in the cloud-init config, as Hetzner employees can technically access that.
		ssh_keys: {
			($SSH_KEY_TYPE)_public: $sshKeys.hostPublicKey,
		    ($SSH_KEY_TYPE)_private: $sshKeys.hostPrivateKey,
		}
		write_files: [
			{
				path: /etc/motd
				permissions: '0644'
				content: $"($vmImage) VM \(type ($vmType)\) for ($session.type) session ($sessionId)"
			},
			{
				path: /etc/ssh/sshd_config.d/10-ssh-hardening.conf
				permissions: '0500'
				content:
$"AllowUsers ($VM_USERNAME)
AuthenticationMethods publickey
MaxAuthTries 2
PermitRootLogin no
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
"
			}
		]
		runcmd: [
			[ "chmod" "777" $BUILD_ROOT_VM_DIR ]
		]
	}
}

# # For build commands:
# try {
# 	print "Initializing build environment"

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
