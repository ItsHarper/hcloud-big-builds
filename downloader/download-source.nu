use std-rfc/iter
use ../common/google-cloud.nu *
use ../common/mount.nu *

export def main []: nothing -> nothing {
	print ""
	print "download-source.nu"
	print "------------------\n"

	verify-running-in-google-cloud

	print "Ensuring needed packages are installed and updated"
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y install repo

	get-build-disk-symlinks
	| format-unformatted-build-disks
	| mount-build-disks

	# Don't capture the output of the previous command
	null
}

# Accepts output from get-build-disk-symlinks as input and returns it unchanged
def format-unformatted-build-disks []: table -> table {
	each {|symlink|
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

		$symlink
	}
}
