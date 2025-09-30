export module ./vms.nu

export def main []: nothing -> nothing {
	print "hcloud-bb list\n"

	print "Subcommands: "
	[
		"vms"
	]
	| each { print $"  hcloud-bb list ($in)"}
	| ignore
}
