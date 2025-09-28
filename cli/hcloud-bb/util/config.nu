use ./cli-constants.nu *
use ./hcloud-wrapper.nu *

# Get the name of the local SSH key for the context (key names have to be unique to the whole Hetzner Cloud project)
export def get-local-ssh-key-name [contextName: string]: nothing -> string {
	let localKeyNamesPath = $"(get-state-dir)/local-ssh-key-names.json"
	if not ($localKeyNamesPath | path exists) {
		"{}" | save $localKeyNamesPath
	}

	let localKeyNames: record = open $localKeyNamesPath
	let localKeyName: oneof<string, nothing> = (
		$localKeyNames
		| get ([{ value: $contextName, optional: true }] | into cell-path)
	)

	return (
		if $localKeyName == null {
			let localKeyName = $"($contextName)-(random chars --length 7)"

			$localKeyNames
			| insert $contextName $localKeyName
			| to json --indent 2
			| save -f $localKeyNamesPath

			$localKeyName
		} else {
			$localKeyName
		}
	)
}
