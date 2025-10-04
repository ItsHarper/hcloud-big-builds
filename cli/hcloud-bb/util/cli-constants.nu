# Settings
export const CONTEXT_NAME = "hcloud-bb"
export const PROJECT_CURRENCY = "$" # TODO(Harper): Get this from the API
export const RESOURCES_NAME_PREFIX = $CONTEXT_NAME
export const TAG_NAME = $CONTEXT_NAME

# TODO(Harper): Verify that Debian 13 doesn't give us issues
export const VM_IMAGE = "debian-13"
export const VM_LOCATION = "nbg1" # Nuremburg, Germany
export const VM_DATACENTER = $"($VM_LOCATION)-dc3" # Use `hcloud datacenter list`
export const VOLUME_FS = "ext4"

export const VOLUME_SIZE_GB_TEST_ONLY = 10
export const VOLUME_SIZE_GB_GRAPHENE = 375
export const VM_MIN_RAM_GiB_GRAPHENE = 64

# Other
export const CLI_UTIL_DIR = path self .
export const CLI_COMMANDS_DIR = path self ../commands
export const INTERNAL_COMMAND_PATH = ($CLI_COMMANDS_DIR)/internal
export const COMMON_CONSTANTS_PATH = path self ../../../common/common-constants.nu
export const CURRENCY_PER_HOUR = $"($PROJECT_CURRENCY)/hr"

export const HCLOUD_CONFIG_FILENAME = "hcloud-cli.toml"
export const CONFIG_DIR_GITIGNORE_CONTENTS = $"
# Contains references to local-only SSH keys and potentially even actual credentials
($HCLOUD_CONFIG_FILENAME)
"

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
