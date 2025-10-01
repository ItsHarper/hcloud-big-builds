export module ./make-friendly/

export def main []: nothing -> nothing {
	print "internal\n"

	print "Commands meant for internal use only\n"

	print "Subcommands: "
	[
		"make-friendly"
	]
	| each { print $"  internal ($in)"}
	| ignore
}
