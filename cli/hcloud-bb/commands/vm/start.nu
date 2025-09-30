use std/assert
use std-rfc/iter
use ../../util/cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

const SCRIPT_DIR = path self .

# Accepts sessionId as either input or argument and passes it through as output
# (the argument takes priority if both are provided)
export def main [sessionId?: string]: oneof<string, nothing> -> string {
	let sessionIdFromInput = $in
	let sessionId: string = $sessionId | default $sessionIdFromInput
	if $sessionId == null { error make { msg: "You must provide a session ID" } }

	set-up-hcloud-context

	let session = get-session $sessionId
	let resourcesName = $session.resourcesName

	let sessionVms = (
		list vms
		| where name == $resourcesName
	)
	if ($sessionVms | length) == 0 {
		create-vm $session
	} else {
		let vm = ($sessionVms | iter only)
		let status = $vm.status
		if $status == "off" {
			print "Starting existing VM"
			hcloud server poweron $resourcesName
		} else if $status == "running" {
			print "VM already started"
		} else {
			error make { msg: $"Unrecognized VM status: ($status)" }
		}
	}

	$sessionId
}

def create-vm [session: record]: nothing -> nothing {
	print "Creating and starting VM"

	let resourcesName = $session.resourcesName
	let volumeDevPath = $session.volumeDevPath
	let ipv4Address = $session.ipv4Address
	let cloudInitConfig = generate-cloud-init-config $session

	let vmInfo = (
		$cloudInitConfig
		| to yaml
		| $"#cloud-config\n\n($in)"
		| hcloud server create --user-data-from-file - --name $resourcesName --volume $resourcesName --primary-ipv4 $resourcesName --type $VM_TYPE --image $VM_IMAGE --datacenter $VM_DATACENTER --quiet --output "json"
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
					# Only allow sudo to be used to run apt-get
					$"ALL=\(ALL\) NOPASSWD:/usr/bin/apt-get"
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
