use ./cli-constants.nu *
use ./hcloud-wrapper.nu *

export const SESSION_STATUS_READY = "READY" # Has no VM
export const SESSION_STATUS_ACTIVE = "ACTIVE" # Has VM

export def save-new-session [
	id: string
	resourcesName: string
	volumeDevPath: string
	ipv4Address: string
]: nothing -> record<id: string, status: string, resourcesName: string, volumeDevPath: string, ipv4Address: string, sshKeysDir: string> {
	let sessionsPath = (get-sessions-path)
	let sshKeysDir = (get-ssh-keys-root-dir)/($id)
	let session = {
		id: $id
		status: $SESSION_STATUS_READY
		resourcesName: $resourcesName
		volumeDevPath: $volumeDevPath
		ipv4Address: $ipv4Address
		sshKeysDir: $sshKeysDir
	}

	mkdir $sshKeysDir
	touch $sessionsPath
	open $sessionsPath
	| default {}
	| upsert $id $session
	| collect
	| save -f $sessionsPath

	$session
}

export def get-session [id: string]: nothing -> record<id: string, status: string, resourcesName: string, volumeDevPath: string, ipv4Address: string, sshKeysDir: string> {
	open (get-sessions-path)
	| get $id
}

export def update-session-status [id: string, status: string]: nothing -> nothing {
	let sessionsPath = (get-sessions-path)
	open $sessionsPath
	| default {}
	| update ([$id, status] | into cell-path) $status
	| collect
	| save -f $sessionsPath
}

export def delete-session [id: string]: nothing -> nothing {
	let sessionsPath = (get-sessions-path)
	open $sessionsPath
	| default {}
	| reject $id
	| collect
	| save -f $sessionsPath

	rm -r (get-ssh-keys-root-dir)/($id)
}

export def clear-sessions []: nothing -> nothing {
	{} | save -f (get-sessions-path)

	let sshKeysRootDir = (get-ssh-keys-root-dir)
	mkdir $sshKeysRootDir
	ls $sshKeysRootDir
	| get name
	| each {|path| rm -r $path}
}

def get-sessions-path []: nothing -> string {
	(get-data-dir)/sessions.json
}

def get-ssh-keys-root-dir []: nothing -> string {
	(get-data-dir)/ssh-keys
}
