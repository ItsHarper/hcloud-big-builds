use common/google-cloud.nu *

let vmInfo = get-vm-info

print "VM info:"
print $vmInfo

try {
	if $vmInfo.isDownloader {
		use downloader/download-source.nu *
		download-source
	}

	if $vmInfo.isBuilder {
		use builder/build-grapheneos.nu *
		build-grapheneos
	}
} catch {|e|
	print -e "Unexpected error occurred:"
	print -e $e.rendered
	if $vmInfo.isGcpVm {
		print -e "In ten minutes, the VM will shut down to save money"
		sudo shutdown -h +10
	}
}
