export module ./create.nu
export module ./shell.nu

export def main []: nothing -> nothing {
	print "Subcommands: "
	[
		"create"
		"install-updates"
		"shell"
	]
	| each { print $"  hcloud-bb vm ($in)"}
	| ignore
}
