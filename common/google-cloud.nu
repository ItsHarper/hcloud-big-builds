export def verify-running-in-google-cloud []: nothing -> nothing {
	print "Verifying environment is Google Cloud"

	# Verify that we're running in Google Cloud, so we don't have to worry
	# too much about accidentally fucking up someone's everyday setup
	http --full metadata.google.internal
	| get headers
	| get response
	| where name == "metadata-flavor" and value == "Google"
	| iter only
}

export def get-vm-info []: nothing -> record {
	let name: string = http -H { Metadata-Flavor: Google } metadata.google.internal/computeMetadata/v1/instance/name
	let isBuilder = $name =~ "builder"
	let isDownloader = $name =~ "downloader"
	{ name: $name, isBuilder: $isBuilder, isDownloader: $isDownloader }
}
