use common/google-cloud.nu *

let vmInfo = get-vm-info

print "VM info:"
print $vmInfo

if $vmInfo.isDownloader {
	use downloader/download-source.nu *
	download-source
}

if $vmInfo.isBuilder {
	use builder/build-grapheneos.nu *
	build-grapheneos
}
