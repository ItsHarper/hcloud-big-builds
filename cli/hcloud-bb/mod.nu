export module ./commands/prune.nu
export module ./commands/start-session.nu

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"prune"
		"start-session"
	]
	| each { print $"  hcloud-bb ($in)"}
	| ignore
}
