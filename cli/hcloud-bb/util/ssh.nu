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

def get-common-ssh-options [session: record]: nothing -> list<string> {
	[
		[ "-o", "StrictHostKeyChecking=yes" ]
		[ "-o", "IdentitiesOnly=yes" ]
		[ "-i", $"($session.sshKeysDir)/client" ]
	]
	| flatten
}

export def wait-for-vm-ping [ipAddress: string]: nothing -> nothing {
	let startTime = date now
	let timeoutDuration = 2min

	print "Connecting to VM"
	mut pingSucceeded = ping $ipAddress

	if not $pingSucceeded {
		print "Waiting for VM to respond to our pings"
	}

	while ((not $pingSucceeded) and ((date now) - $startTime) < $timeoutDuration) {
		sleep 200ms
		$pingSucceeded = ping $ipAddress
	}

	if $pingSucceeded {
		print $"VM responded after (((date now) - $startTime) | format duration sec)"
	} else {
		error make { msg: $"Timed out after ($timeoutDuration) of waiting for VM to respond to our pings" }
	}
}

def ping [ipAddress: string]: nothing -> bool {
	^ping -c 1 $ipAddress
	| complete
	| $in.exit_code == 0
}
