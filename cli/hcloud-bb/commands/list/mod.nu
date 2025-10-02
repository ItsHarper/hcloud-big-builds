export module ./sessions.nu
export module ./vm-types.nu
export module ./vms.nu

export def main []: nothing -> nothing {
	print "hcloud-bb list\n"

	print "Subcommands: "
	[
		"sessions"
		"vm-types"
		"vms"
	]
	| each { print $"  hcloud-bb list ($in)"}
	| ignore
}
