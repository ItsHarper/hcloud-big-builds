use std-rfc/iter
use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/vm

const SCRIPT_DIR = path self .

export def main []: nothing -> record {
	set-up-hcloud-context

	let sessionTypeInfo: record = (
		[
			[description sessionTypeInfo];
			["GrapheneOS" { type: $SESSION_TYPE_GRAPHENE, volumeSizeGiB: $VOLUME_SIZE_GRAPHENE_SESSION_GiB }]
			["Testing only" { type: $SESSION_TYPE_TEST_ONLY, volumeSizeGiB: $VOLUME_SIZE_TEST_ONLY_SESSION_GiB }]
		]
		| input list -d description "Select session type"
		| get sessionTypeInfo
	)
	let sessionType: string = $sessionTypeInfo.type
	let volumeSizeGiB: int = $sessionTypeInfo.volumeSizeGiB

	let sessionId = random chars --length 7
	let resourcesName = ($RESOURCES_NAME_PREFIX)-($sessionId)

	# TODO(Harper): Determine whether the hcloud docs actually mean "GB" or if they really mean "GiB"
	print "Creating volume"
	let volumeInfo: record = (
		hcloud volume create --name $resourcesName --size $volumeSizeGiB --format $VOLUME_FS --location $VM_LOCATION --quiet --output "json"
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
		error make { msg: $"Hetzner responded with error code ($ipResponse.status)" }
	}
	let ipv4Info = $ipResponse.body.primary_ip

	save-new-session $sessionId $sessionType $resourcesName $volumeInfo.volume.linux_device $ipv4Info.ip

	try {
		let buildSession = $sessionType != $SESSION_TYPE_TEST_ONLY
		vm start $sessionId $buildSession
	} catch {|e|
		print -e "Failed to start VM (session is still valid):"
		print -e $e.rendered
		# Don't throw an error, the session was still created successfully.
	}

	print $"Created session ($sessionId)"
	get-session $sessionId
}

# TODO(Harper): For pruning system:
# print -e "ERROR: Failed to destroy VM. You are leaking money."
