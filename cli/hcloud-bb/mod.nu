export module ./commands/session/
export module ./commands/prune.nu
export module ./commands/vm/

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"session"
		"prune"
		"vm"
	]
	| each { print $"  hcloud-bb ($in)"}
	| ignore
}
