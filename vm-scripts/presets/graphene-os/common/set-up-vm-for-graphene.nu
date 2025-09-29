export def main []: nothing -> nothing {
	print "Ensuring needed packages are installed"
	sudo apt-get update
	# The `repo` package is in the contrib component, which is enabled by default on Hetzner's image
	sudo apt-get -y install repo yarnpkg zip rsync

	print "Configuring git"
	git config --global user.email "hcloud-bb-builder@example.com"
	git config --global user.name "hcloud-bb-builder"
}
