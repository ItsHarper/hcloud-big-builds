use std-rfc/iter
use ../../../common/graphene-constants.nu *
use ../../../common/debian.nu *
use ../../../common/google-cloud.nu *
use ../../../common/mount.nu *
use ../../../common/sync.nu *

const PREPARE_PIXEL_FILES_SCRIPT_PATH = path self ./prepare-for-pixel-vendor-files-generation.sh

export def main []: nothing -> nothing {
	print ""
	print "download-source.nu"
	print "------------------\n"

	verify-running-in-google-cloud
	install-and-update-debian-packages

	let buildSsdDevicePath = "/dev/disk/by-id/google-local-nvme-ssd-0"
	let buildSsdMountpoint = "/mnt/build-ssd"
	sudo mkfs.ext4 -F $buildSsdDevicePath
	sudo mkdir -p $buildSsdMountpoint
	sudo mount $buildSsdDevicePath $buildSsdMountpoint
	sudo chmod a+w $buildSsdMountpoint
	$buildSsdMountpoint | prepare-build-dir

	# get-build-disk-symlinks
	# | format-unformatted-build-disks
	# | mount-build-disks
	# | each { prepare-build-dir }

	# Don't capture the output of the previous command
	null
}

def prepare-build-dir []: string -> nothing {
	let buildDir = $in
	sync-source $buildDir

	cd $buildDir
	print "Preparing for pixel vendor files generation"
	bash $PREPARE_PIXEL_FILES_SCRIPT_PATH
	touch $INITIAL_SETUP_COMPLETED_FILENAME

	print $"Finished setting up ($buildDir)"
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
