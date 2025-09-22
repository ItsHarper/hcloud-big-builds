use common/google-cloud.nu *

let vmInfo = get-vm-info

print "VM info:"
print $vmInfo

try {
	timeit {
		if $vmInfo.isDownloader {
			use downloader/download-source.nu *
			download-source
		}

		if $vmInfo.isBuilder {
			use builder/build-grapheneos.nu *
			build-grapheneos
		}
	}
	| format duration min
	| print $"Finished. Complete process took ($in)"

	if $vmInfo.isGcpVm {
		print "The VM will now shut down to save money"
		sudo shutdown -h now
	}
} catch {|e|
	print -e "Unexpected error occurred:"
	print -e $e.rendered
	if $vmInfo.isGcpVm {
		print -e "In ten minutes, the VM will shut down to save money"
		sudo shutdown -h +10
	}
}
