use std-rfc/iter
use ../common/graphene-constants.nu *
use ($GRAPHENE_COMMON_DIR)/debian.nu *
use ($GRAPHENE_COMMON_DIR)/google-cloud.nu *
use ($GRAPHENE_COMMON_DIR)/mount.nu *
use ($GRAPHENE_COMMON_DIR)/sync.nu *

export def main []: nothing -> nothing {
	print ""
	print "build-grapheneos.nu"
	print "-------------------\n"

	verify-running-in-google-cloud
	install-and-update-debian-packages


	# Update path according to GrapheneOS build instructions
	$env.path ++= [
			"/sbin"
			"/usr/sbin"
			"/usr/local/sbin"
	]

	get-build-disk-symlinks
	| mount-build-disks
	| each {|buildDir|
		if not (($buildDir)/($INITIAL_SETUP_COMPLETED_FILENAME) | path exists) {
			error make { msg: $"The intial setup has not been completed. ($buildDir) needs to be attached to a download VM first." }
		}
		# TODO(Harper): Decide whether to un-comment or delete
		# sync-source $buildDir
		null
	}
	| ignore
}

def build [buildDir: string]: nothing -> nothing {
	$PIXEL_DEVICES_TO_BUILD
	| each {|pixelCodename|
		print $"Generating vendor files for ($pixelCodename)"
		timeit {
			adevtool generate-all -d $pixelCodename
		}
		| format duration min
		| print $"vendor file generation took ($in)"
	}
	| ignore
}
