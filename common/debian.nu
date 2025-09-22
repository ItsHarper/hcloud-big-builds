export def install-and-update-debian-packages []: nothing -> nothing {
	print "Ensuring needed packages are installed and updated"
	sudo apt-get -y update
	# TODO(Harper): Hold back unused Google Cloud SDK packages
	sudo apt-get -y upgrade
	sudo apt-get -y install repo yarnpkg zip rsync
	null
}
