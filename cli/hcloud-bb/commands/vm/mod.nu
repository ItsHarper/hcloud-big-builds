export module ./create.nu
export module ./list.nu
export module ./shell.nu

export def main []: nothing -> nothing {
	print "hcloud-bb vm\n"

	print "Operates only on the ephemeral VMs that belong to sessions."
	print "Use `hcloud-bb session` for higher-level commands whose results will"
	print "persist through the lifetime of the session, not just an individual VM.\n"

	print "Subcommands: "
	[
		"create"
		"list"
		"shell"
	]
	| each { print $"  hcloud-bb vm ($in)"}
	| ignore
}
