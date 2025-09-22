export module ./commands/start-session.nu

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"start-session"
	]
	| each { print $"  hcloud-bb ($in)"}
	| ignore
}
