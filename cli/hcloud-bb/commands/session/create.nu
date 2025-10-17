use std-rfc/iter
use ../../util/cli-constants.nu *
use ($CLI_UTIL_DIR)/hcloud-context-management.nu *
use ($CLI_UTIL_DIR)/hcloud-wrapper.nu *
use ($CLI_UTIL_DIR)/state.nu *
use ($CLI_COMMANDS_DIR)/session/run-build.nu

const SCRIPT_DIR = path self .

export def main [--no-build]: nothing -> record {
	set-up-hcloud-context

	let sessionType: record = (
		get-session-types
		| input list -d description "Select session type"
	)
	let volumeSizeGB: int = $sessionType.volumeSizeGB

	let sessionId = random chars --length 7
	let resourcesName = ($RESOURCES_NAME_PREFIX)-($sessionId)

	print "Creating volume"
	let volumeInfo: record = (
		hcloud volume create --name $resourcesName --size $volumeSizeGB --format $VOLUME_FS --location $VM_LOCATION --quiet --output "json"
		| from json
	)

	print "Creating IPv4 address"
	let ipv4Info: record = (
		hcloud primary-ip create --name $resourcesName --datacenter $VM_DATACENTER --type ipv4 --auto-delete=false --output json
		| from json
		| get primary_ip
	)

	save-new-session $sessionId $sessionType.id $resourcesName $volumeInfo.volume.linux_device $ipv4Info.ip
	print $"Successfully created session"

	if not $no_build {
		try {
			print "Starting build"
			run-build $sessionId
			print "Build succeeded"
		} catch {|e|
			print -e "Build failed (session is still valid):"
			print -e $e.rendered
			# Don't throw an error, the session was still created successfully.
		}
	}

	print $"Created session ($sessionId)"
	get-session $sessionId
}

# TODO(Harper): For pruning system:
# print -e "ERROR: Failed to destroy VM. You are leaking money."
