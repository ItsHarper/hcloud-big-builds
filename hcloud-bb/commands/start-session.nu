use ../util/hcloud-bb-constants.nu *
use ../util/hcloud-context-management.nu *
use ../util/hcloud-wrapper.nu *

export def main []: nothing -> nothing {
	set-up-hcloud-context

	# While server creation is done in more than one context, it's (currently) important that
	# the error handling is all handled at this level, so it's better not to abstract it into
	# a custom command.
	try {
		# hcloud server create --name $SERVER_NAME --type $SERVER_TYPE --image $SERVER_IMAGE
		true
	} catch {|e|
		# TODO(Harper): Ensure that the machine is not left in a half-created state
		print -e "Cause of failure to create server:"
		print -e $e.rendered
		error make { msg: "Failed to create server, see prior output" }
	}

	# Now that the server exists, an error from this point forwards must not prevent
	# the end of the function from being reached
	# TODO: Guarantee this using a future nushell feature or community-provided solution:
	#       https://github.com/nushell/nushell/issues/15941

	let setupSucceeded: bool = try {
		# TODO(Harper): Run setup without capturing output
		print "Setup step finished"
		true
	} catch {|e|
		print -e "Setup step failed, see prior output"
		false
	}

	let buildSucceeded: bool = if $setupSucceeded {
		try {
			# TODO(Harper): Run build without capturing output
			print "Build finished"
			true
		} catch {|e|
			print -e "Build step failed, see prior output"
			false
		}
	} else {
		false
	}

	try {
		# TODO(Harper): Destroy server
	} catch {|e|
		print -e "Cause of failure to destroy server:"
		print -e $e.rendered
		error make { msg: "CRITICAL ERROR: Failed to destroy server. You are leaking money." }
	}

	if not $setupSucceeded or not $buildSucceeded {
		error make { msg: "Failed to start session, see prior output" }
	}

	null
}
