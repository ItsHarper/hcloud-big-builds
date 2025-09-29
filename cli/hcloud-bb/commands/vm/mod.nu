export module ./create/

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"create"
		"install-updates"
	]
	| each { print $"  hcloud-bb vm ($in)"}
	| ignore
}
