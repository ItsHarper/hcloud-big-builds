use std-rfc/iter
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

	let session = get-session $sessionId
	let sessionId: string = $session.id
	let resourcesName = $session.resourcesName
	print "Getting list of existing VMs"
	let sessionVms = (
		list vms
		| where name == $resourcesName
	)

	# Make sure the status is set to ACTIVE before we actually start
	# the VM, so that it can't get pruned
	update-session-status $sessionId $SESSION_STATUS_ACTIVE

	try {
		if ($sessionVms | length) == 0 {
			create-vm $session $startingBuild
		} else {
			print "Reusing existing VM:"
			let vm = ($sessionVms | iter only)
			print ($vm | table --expand)
			let status = $vm.status
			if $status == "off" {
				print "Starting VM"
				hcloud server poweron $resourcesName
			} else if $status != "running" {
				error make { msg: $"Unrecognized VM status: ($status)" }
			}
		}
	} catch {|e|
		print -e "Failed to start VM:"
		print -e $e.rendered

		update-session-status $sessionId $SESSION_STATUS_READY
		error make { msg: $"Failed to start VM ($e.msg)" }
	}

	$sessionId
}

def create-vm [session: record, startingBuild: bool]: nothing -> nothing {
	let sessionType: string = $session.type
	let resourcesName: string = $session.resourcesName
	let volumeDevPath: string = $session.volumeDevPath
	let ipv4Address: string = $session.ipv4Address
	let vmType: string = (
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
	)

	print $"Are you sure you would like to create a VM of this type?"
	print (
		hcloud server-type describe --output json $vmType
		| from json
		| internal make-friendly vm-type $VM_LOCATION
		| table --expand
	)
	let confirmed = [[text result]; [Yes true] [No false]] | input list -d text | get result

	if not $confirmed {
		error make { msg: "User did not confirm VM creation" }
	}

	print "Generating VM configuration"
	let cloudInitConfig = generate-cloud-init-config $session

	print "Creating and starting VM"
	let vmInfo = (
		$cloudInitConfig
		| to yaml
		| $"#cloud-config\n\n($in)"
		| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --primary-ipv4 $resourcesName --type $vmType --image $VM_IMAGE --datacenter $VM_DATACENTER --quiet --output "json"
		| from json
		| get server
	)
}

def generate-cloud-init-config [session: record<volumeDevPath: string>]: nothing -> record {
	let sshKeys = get-ssh-keys-for-vm-creation $session.id
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
