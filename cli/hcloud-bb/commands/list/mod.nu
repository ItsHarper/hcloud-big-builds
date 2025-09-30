export module ./sessions.nu
export module ./vms.nu

export def main []: nothing -> nothing {
	print "hcloud-bb list\n"

	print "Subcommands: "
	[
		"sessions"
		"vms"
	]
	| each { print $"  hcloud-bb list ($in)"}
	| ignore
}
