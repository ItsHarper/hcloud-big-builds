use ./cli-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ./state.nu *

export const SSH_KEY_TYPE = "ed25519"

export def get-ssh-keys-for-vm-creation [
	sessionId: string
]: nothing -> record<hostPublicKey: string, hostPrivateKey: string, clientPublicKey: string> {
	let session = get-session $sessionId
	let sshKeysDir = $session.sshKeysDir
	let hostPublicKeyPath = ($sshKeysDir)/host.pub
	let hostPrivateKeyPath = ($sshKeysDir)/host
	let clientPublicKeyPath = ($sshKeysDir)/client.pub
	let clientPrivateKeyPath = ($sshKeysDir)/client

	if not ($clientPrivateKeyPath | path exists) {
		print "Generating host and client SSH keys"
		mkdir $sshKeysDir
		ssh-keygen -q -t $SSH_KEY_TYPE -N "" -f $hostPrivateKeyPath
		ssh-keygen -q -t $SSH_KEY_TYPE -N "" -f $clientPrivateKeyPath

		print "Adding/updating known_hosts entry"
		ssh-keygen -q -R $session.ipv4Address err> /dev/null
		$"($session.ipv4Address) (open --raw $hostPublicKeyPath | str trim)\n"
		| save --append ~/.ssh/known_hosts
	}

	{
		hostPublicKey: (open --raw $hostPublicKeyPath)
		hostPrivateKey: (open --raw $hostPrivateKeyPath)
		clientPublicKey: (open --raw $clientPublicKeyPath)
	}
}

export def --wrapped ssh-into-session-vm [--command: string, sessionId: string, ...rest]: nothing -> any {
	let session = get-session $sessionId
	let ip = $session.ipv4Address
	ssh ...(get-common-ssh-options $session) $"($VM_USERNAME)@($ip)" ($command | default "")
}

export def rsync-to-session-vm [src: string, dest: string, sessionId: string]: nothing -> nothing {
	let session = (get-session $sessionId)
	let ip = $session.ipv4Address
	rsync --recursive --perms --rsh $"ssh ((get-common-ssh-options $session) | str join ' ')" $src ($VM_USERNAME)@($ip):($dest)
}

export def rsync-from-session-vm [src: string, dest: string, sessionId: string]: nothing -> nothing {
	let session = (get-session $sessionId)
	let ip = $session.ipv4Address
	rsync --recursive --perms --progress --rsh $"ssh ((get-common-ssh-options $session) | str join ' ')" ($VM_USERNAME)@($ip):($src) $dest
}

def get-common-ssh-options [session: record]: nothing -> list<string> {
	[
		[ "-o", "StrictHostKeyChecking=yes" ]
		[ "-o", "IdentitiesOnly=yes" ]
		[ "-i", $"($session.sshKeysDir)/client" ]
	]
	| flatten
}
