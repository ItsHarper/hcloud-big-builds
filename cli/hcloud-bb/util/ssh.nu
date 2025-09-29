use ./cli-constants.nu *
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

export def --wrapped ssh-into-session-vm [sessionId: string, ...rest]: nothing -> any {
	let session = get-session $sessionId
	let clientPrivateKeyPath = ($session.sshKeysDir)/client
	let ip = $session.ipv4Address
	print "Connecting to VM"
	wait-for-vm-ping $ip
	ssh -oStrictHostKeyChecking=yes -o IdentitiesOnly=yes -i $clientPrivateKeyPath ...$rest ($VM_USERNAME)@($ip)
}

def wait-for-vm-ping [ipAddress: string]: nothing -> nothing {
	let startTime = date now
	let timeoutDuration = 2min
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
