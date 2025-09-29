use ./cli-constants.nu *
use ./hcloud-wrapper.nu *

export def set-up-hcloud-context []: nothing -> nothing {
	let desiredContext = $CONTEXT_NAME

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

	null
}
