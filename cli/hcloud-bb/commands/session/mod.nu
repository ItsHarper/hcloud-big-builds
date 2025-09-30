export module ./create.nu
export module ./destroy.nu
export module ./prepare-build-root.nu

export def main []: nothing -> nothing {
	print "hcloud-bb vm\n"

	print "Performs operations whose results will persist through an entire session\n"

	print "Subcommands: "
	[
		"create"
		"destroy"
		"prepare-build-root"
	]
	| each { print $"  hcloud-bb session ($in)"}
	| ignore
}
