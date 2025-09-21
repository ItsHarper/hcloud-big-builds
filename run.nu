let vmName: string = http -H { Metadata-Flavor: Google } metadata.google.internal/computeMetadata/v1/instance/name

let isBuilder = $vmName =~ "builder"
let isDownloader = $vmName =~ "downloader"

print "VM info:"
print { name: $vmName, isBuilder: $isBuilder, isDownloader: $isDownloader }

if $isDownloader {
	use downloader/download-source.nu *
	download-source
}

if $isBuilder {
	use builder/build-grapheneos.nu *
	build-grapheneos
}
