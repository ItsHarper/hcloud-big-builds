use std/assert

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
export def verify-running-in-google-cloud []: nothing -> nothing {
	print "Verifying environment is Google Cloud"
	assert (get-vm-info).isGcpVm
}

export def get-vm-info []: nothing -> record {
	let name: oneof<string, nothing> = try {
		http --headers { Metadata-Flavor: Google } metadata.google.internal/computeMetadata/v1/instance/name
	}

	if $name == null {
		{
			isGcpVm: false
		}
	} else {
		{
			isGcpVm: true
			name: $name
			isBuilder: ($name =~ "builder")
			isDownloader: ($name =~ "downloader")
		}
	}
}
