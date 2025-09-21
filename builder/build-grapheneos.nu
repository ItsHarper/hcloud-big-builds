use std-rfc/iter

export def build-grapheneos []: nothing -> nothing {
	print ""
	print "build-grapheneos.nu"
	print "-------------------\n"

	print "Ensuring needed packages are installed and updated"
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install repo yarnpkg zip rsync
}
