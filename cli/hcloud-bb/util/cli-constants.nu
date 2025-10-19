export const COMMON_CONSTANTS_PATH = path self ../../../common/common-constants.nu
use $COMMON_CONSTANTS_PATH *

# Settings
export const CONTEXT_NAME = "hcloud-bb"
export const PROJECT_CURRENCY = "$" # TODO(Harper): Get this from the API
export const RESOURCES_NAME_PREFIX = $CONTEXT_NAME
export const TAG_NAME = $CONTEXT_NAME

export const VM_IMAGE = "debian-13"
export const VM_LOCATION = "nbg1" # Nuremburg, Germany
export const VM_DATACENTER = $"($VM_LOCATION)-dc3" # Use `hcloud datacenter list`
export const VOLUME_FS = "ext4"

export const VM_NUSHELL_VERSION = "0.107.0"

# Other
export const CLI_UTIL_DIR = path self .
export const CLI_COMMANDS_DIR = path self ../commands
export const CLI_OUT_DIR = ($HCLOUD_BB_LOCAL_DIR)/out
export const INTERNAL_COMMAND_PATH = ($CLI_COMMANDS_DIR)/internal
export const PRUNE_LOG_PATH = path self ../../../.prune-log.json
export const CURRENCY_PER_HOUR = $"($PROJECT_CURRENCY)/hr"

export const HCLOUD_CONFIG_FILENAME = "hcloud-cli.toml"
export const CONFIG_DIR_GITIGNORE_CONTENTS = $"
# Contains references to local-only SSH keys and potentially even actual credentials
($HCLOUD_CONFIG_FILENAME)
"

export def get-session-types []: nothing -> table<id: string, description: string, volumeSizeGB: int, vmTypeConstraint: closure, outputsToDownload: table<vmRelativePath: string, localRelativePath: string>>  {
	[
		{
			id: "graphene-os"
			description: "GrapheneOS"
			volumeSizeGB: 375
			vmTypeConstraint: {|vm|
				(
					$vm.cpu_type == "dedicated" and
					$vm.architecture == "x86" and
					$vm.memory >= 64
				)
			}
			outputsToDownload: (
				$GRAPHENE_BUILD_TARGETS
				| each {|buildTarget|
					let localTargetDir = $"($buildTarget)/" # The trailing slash tells rsync to put the files in the folder, instead of giving them the folder's name
					let vmTargetDir = $"out/target/product/($buildTarget)"
					[
						{ vmRelativePath: ($vmTargetDir)/*.img, localRelativePath: $localTargetDir }
						{ vmRelativePath: ($vmTargetDir)/fastboot-info.txt, localRelativePath: $localTargetDir }
						{ vmRelativePath: ($vmTargetDir)/android-info.txt, localRelativePath: $localTargetDir }
					]
				}
				| flatten
			)
		}
		{
			id: "test-only"
			description: "Testing only"
			volumeSizeGB: 10
			vmTypeConstraint: {|vm| true}
			outputsToDownload: []
		}
	]
}

export def get-config-dir []: nothing -> string {
	let result = (
		$env
		| default $"($env.HOME)/.config" XDG_CONFIG_HOME
		| get XDG_CONFIG_HOME
		| $"($in)/hcloud-bb"
	)
	mkdir $result
	$result
}

export def get-data-dir []: nothing -> string {
	let result = (
		$env
		| default $"($env.HOME)/.local/share" XDG_DATA_HOME
		| get XDG_DATA_HOME
		| $"($in)/hcloud-bb"
	)
	mkdir $result
	$result
}

export def get-state-dir []: nothing -> string {
	let result = (
		$env
		| default $"($env.HOME)/.local/state" XDG_STATE_HOME
		| get XDG_STATE_HOME
		| $"($in)/hcloud-bb"
	)
	mkdir $result
	$result
}
