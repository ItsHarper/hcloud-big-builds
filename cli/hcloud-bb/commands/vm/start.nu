use ../../util/cli-constants.nu *
use $COMMON_CONSTANTS_PATH *
use $INTERNAL_COMMAND_PATH
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/ssh.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/list

const SCRIPT_DIR = path self .

# vmTypeConstraint accepts a VM record and returns a bool that indicates if the
# VM is suitable
export def main [sessionId: string, vmTypeConstraint?: closure]: nothing -> string {
	set-up-hcloud-context
	let vmTypeConstraint = $vmTypeConstraint | default { {|vm| true} }
	let session = get-session $sessionId

	try {
		let action = get-needed-action $session $vmTypeConstraint

		# Make sure the status is set to ACTIVE before we actually change
		# the state of a VM, so that it can't get pruned
		print $"Marking session as ($SESSION_STATUS_ACTIVE)"
		update-session-status $sessionId $SESSION_STATUS_ACTIVE

		do $action

		wait-for-vm-ping $session.ipv4Address
		# TODO(Harper): If the ping took more than a second, try making a no-op
		#               SSH connection a few times. Sometimes it starts responding
		#               to pings before the SSH server is ready.

		print "Syncing scripts to VM"
		rsync-to-session-vm $TOP_LEVEL_COMMON_DIR $HCLOUD_BB_VM_DIR $sessionId
		rsync-to-session-vm $VM_SCRIPTS_DIR $HCLOUD_BB_VM_DIR $sessionId
		rsync-to-session-vm ($VM_CONFIG_DIR)/ /home/($VM_USERNAME)/.config $sessionId
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
def get-needed-action [session: record, vmTypeConstraint: closure]: nothing -> closure {
	let sessionId: string = $session.id
	let resourcesName = $session.resourcesName

	print "Getting list of existing VMs"
	let existingVm: oneof<record, nothing> = (
		list vms
		| where name == $resourcesName
		| get --optional 0
	)

	if $existingVm != null {
		# We can only reuse existing VMs if there is either no constraint or the existing VM matches it
		if $vmTypeConstraint == null or (do $vmTypeConstraint $existingVm.server_type) {
			return { reuse-existing-vm $existingVm }
		}
	}

	let selectedVmType: string = (prompt-for-vm-type $vmTypeConstraint)

	confirm-vm-creation $selectedVmType $existingVm

	# Return closure that will be run later
	{
		if $existingVm != null {
			# It's critical that we do NOT change the session's status, so we must use `hcloud` directly

			print "Shutting down existing VM"
			hcloud server shutdown --wait=true --wait-timeout 120s --quiet $existingVm.id

			print "Deleting existing VM"
			hcloud server delete $existingVm.id
		}

		create-vm $session $selectedVmType
	}
}

def confirm-vm-creation [vmType: string, existingVm: oneof<record, nothing>]: nothing -> nothing {
	print "Fetching VM type details"
	let vmTypeDetails = (
		hcloud server-type describe --output json $vmType
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
}

def prompt-for-vm-type [vmTypeConstraint: closure]: nothing -> string {
	list vm-types
	| where $vmTypeConstraint
	| input list --fuzzy "Which type of VM would you like to create?"
	| get name
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

def create-vm [session: record, vmType: string]: nothing -> nothing {
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

def wait-for-vm-ping [ipAddress: string]: nothing -> nothing {
	let startTime = date now
	let timeoutDuration = 2min

	print "Connecting to VM"
	mut pingSucceeded = ping $ipAddress
	let initialPingSucceeded = $pingSucceeded

	if not $pingSucceeded {
		print "Waiting for VM to respond to our pings"
	}

	while ((not $pingSucceeded) and ((date now) - $startTime) < $timeoutDuration) {
		sleep 200ms
		$pingSucceeded = ping $ipAddress
	}

	if not $pingSucceeded {
		error make { msg: $"Timed out after ($timeoutDuration) of waiting for VM to respond to our pings" }
	}
	if not $initialPingSucceeded {
		print $"VM responded after (((date now) - $startTime) | format duration sec)"
	}
}

def ping [ipAddress: string]: nothing -> bool {
	^ping -c 1 $ipAddress
	| complete
	| $in.exit_code == 0
}
