export module ./create.nu

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"create"
	]
	| each { print $"  hcloud-bb session ($in)"}
	| ignore
}
