export module ./create.nu

export def main []: nothing -> nothing {
	print "hcloud-bb vm\n"

	print "Performs operations whose results will persist through an entire session\n"

	print "Subcommands: "
	[
		"create"
	]
	| each { print $"  hcloud-bb session ($in)"}
	| ignore
}
