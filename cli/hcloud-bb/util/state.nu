use ./cli-constants.nu *
use ./hcloud-wrapper.nu *

export def save-session [
	id: string
	resourcesName: string
	volumeDevPath: string
]: nothing -> nothing {
	let sessionsPath = $"(get-data-dir)/sessions.json"
	touch $sessionsPath
	open $sessionsPath
	| default {}
	| upsert $id {
		resourcesName: $resourcesName
		volumeDevPath: $volumeDevPath
	}
	| collect
	| save -f $sessionsPath
}

export def get-session [id: string]: nothing -> record {
	let sessionsPath = $"(get-data-dir)/sessions.json"
	open $sessionsPath
	| get $id
}

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
