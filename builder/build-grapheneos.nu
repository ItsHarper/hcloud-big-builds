use std-rfc/iter
use ../common/google-cloud.nu *

export def build-grapheneos []: nothing -> nothing {
	print ""
	print "build-grapheneos.nu"
	print "-------------------\n"

	verify-running-in-google-cloud

	print "Ensuring needed packages are installed and updated"
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install repo yarnpkg zip rsync

	# Update path according to GrapheneOS build instructions
	$env.path ++= [
			"/sbin"
			"/usr/sbin"
			"/usr/local/sbin"
	]
}
