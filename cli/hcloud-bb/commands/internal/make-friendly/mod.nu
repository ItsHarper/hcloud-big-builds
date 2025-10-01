export module ./vm.nu
export module ./vm-type.nu

export def main []: nothing -> nothing {
	print "internal make-friendly\n"

	print "Takes full hcloud input, extracts out the important parts, and massages them to be easy to use\n"

	print "Subcommands: "
	[
		"vm"
		"vm-type"
	]
	| each { print $"  internal make-friendly ($in)"}
	| ignore
}
