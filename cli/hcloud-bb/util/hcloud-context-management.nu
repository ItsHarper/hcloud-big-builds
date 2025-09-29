use ./state.nu *
use ./cli-constants.nu *
use ./hcloud-wrapper.nu *

export def set-up-hcloud-context []: nothing -> nothing {
	let desiredContext = $CONTEXT_NAME
	# Our VMs are ephemeral, so the SSH keys to log into them are considered state, not configuration
	let sshKeysDir = (get-state-dir)/hcloud-ssh-keys
	let sshKeyName = get-local-ssh-key-name $desiredContext
	let sshKeyPath = ($sshKeysDir)/($sshKeyName)

	# Before we potentially collect and/or generate credentials,
	# write the .gitignore file to the config folder to prevent
	# them from being erroneously committed
	$CONFIG_DIR_GITIGNORE_CONTENTS
	| save --force (get-config-dir)/.gitignore

	if (hcloud context active) != $desiredContext {
		# TODO(Harper): Check if the context exists but is not active
		print "Make a read/write API token for the appropriate Hetzner Cloud project (ideally named to indicate the computer it will be saved to)."
		print "When prompted, provide the token."
		hcloud context create $desiredContext
		null
	}

	if not ($sshKeyPath | path exists) {
		mkdir $sshKeysDir
		print $"Generating SSH key pair `($sshKeyName)`"
		ssh-keygen -t ed25519 -N "" -f $sshKeyPath

		print $"Uploading SSH public key `($sshKeyName)`"
		hcloud ssh-key create --name $sshKeyName --public-key-from-file $"($sshKeyPath).pub"

		# Configure the `hcloud` CLI to automatically grant this key access to new VMs it creates
		hcloud config set default-ssh-keys $sshKeyName

		null
	} else {
		# TODO(Harper): Verify that the key has been uploaded
		# TODO(Harper): Verify that the key name is listed by `hcloud config get default-ssh-keys`
		null
	}

	null
}
