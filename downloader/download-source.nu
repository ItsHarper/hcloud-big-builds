use std-rfc/iter
use ../common/google-cloud.nu *

export def download-source []: nothing -> nothing {
	print ""
	print "download-source.nu"
	print "------------------\n"

	verify-running-in-google-cloud

	print "Ensuring needed packages are installed and updated"
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install repo

	# Update path according to GrapheneOS build instructions
	$env.path ++= [
			"/sbin"
			"/usr/sbin"
			"/usr/local/sbin"
	]

	let buildDiskSymlinks = (
			# Wildcards error out if no matching results are found,
			# so we do a complete listing and perform filtering
			ls --long --full-paths /dev/disk/by-id/
			| rename --column { name: "path" }
			# We don't care about the partitions (if any)
			| where $it.path =~ "google-grapheneos-build-" and not ($it.path =~ "part")
	)

	$buildDiskSymlinks
	| each {|symlink|
			let name: string = $symlink | get path | parse --regex 'google-(?<name>grapheneos-build-\d+)' | iter only | get name
			let symlinkTarget: string = $symlink | get target

			let blkIdResult = sudo blkid $symlinkTarget | complete
			print $"blkid ($symlinkTarget):"
			print $blkIdResult
			let needsFormatting = ($blkIdResult.exit_code != 0) or not ($blkIdResult.stdout | str contains -i 'TYPE="ext4"')

			if $needsFormatting {
				# This disk needs formatting
				# https://cloud.google.com/compute/docs/disks/format-mount-disk-linux
				sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $symlinkTarget

				# Don't capture the output of the previous command
				null
			}

			let mountpointPath = $"/mnt/disks/($name)"
			if (mountpoint $mountpointPath | complete | get exit_code) != 0 {
				print $"Mounting ($mountpointPath)"
				sudo mkdir -p $mountpointPath
				sudo mount -o discard,defaults $symlinkTarget $mountpointPath
			} else {
				print $"Verified mountpoint at ($mountpointPath)"
			}

			# Don't capture the output of the previous command
			null
	}
	| ignore
}
