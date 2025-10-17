export module ./create.nu
export module ./destroy.nu
export module ./download-outputs.nu
export module ./run-build.nu

export def main []: nothing -> nothing {
	print "hcloud-bb vm\n"

	print "Performs operations whose results will persist through an entire session\n"

	print "Subcommands: "
	[
		"create"
		"destroy"
		"download-outputs"
		"run-build"
	]
	| each { print $"  hcloud-bb session ($in)"}
	| ignore
}
