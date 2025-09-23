# Settings
export const CONTEXT_NAME = "hcloud-bb"

# Other
export const HCLOUD_CONFIG_FILENAME = "hcloud-cli.toml"
export const CONFIG_DIR_GITIGNORE_CONTENTS = $"
# As of version 1.52.0, the hcloud cli stores its credentials in its config file
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
