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

export def main []: nothing -> record {
	set-up-hcloud-context

	let sessionId = random chars --length 7
	let resourcesName = ($RESOURCES_NAME_PREFIX)-($sessionId)

	# TODO(Harper): Determine whether the hcloud docs actually mean "GB" or if they really mean "GiB"
	print "Creating volume"
	let volumeInfo: record = (
		hcloud volume create --name $resourcesName --size $VOLUME_SIZE_GiB --format $VOLUME_FS --location $VM_LOCATION --output "json"
		| from json
	)

	print "Creating IPv4 address"
	# TODO(Harper): Switch back to hcloud cli once they fix this command
	# let ipv4Info: record = (
	# 	hcloud primary-ip create --name $resourcesName --datacenter $VM_DATACENTER --type ipv4 --auto-delete=false
	# 	| from json
	# )

	let token: string = (
		open (get-config-dir)/($HCLOUD_CONFIG_FILENAME)
		| get contexts
		| iter only
		| get token
	)
	let ipResponse = (
		{
			name: $resourcesName
			type: "ipv4"
			datacenter: "nbg1-dc3"
			assignee_type: "server"
			auto_delete: false
		}
		| http post --allow-errors --full --headers { Authorization: $"Bearer ($token)" } --content-type application/json "https://api.hetzner.cloud/v1/primary_ips"
	)
	if $ipResponse.status < 200 or $ipResponse.status >= 300 {
		print -e "Full IP creation response:"
		print -e ($ipResponse | table --expand)
		error make { msg: $"Server responded with error code ($ipResponse.status)" }
	}
	let ipv4Info = $ipResponse.body.primary_ip

	let session = save-session $sessionId $resourcesName $volumeInfo.volume.linux_device $ipv4Info.ip

	print $"Created session ($sessionId)"

	$session
}

# For pruning system:
# print -e "ERROR: Failed to destroy VM. You are leaking money."
