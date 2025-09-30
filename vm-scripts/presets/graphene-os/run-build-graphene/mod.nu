use std-rfc/iter
use ../common/graphene-constants.nu *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu

const RUN_BUILD_SCRIPT_PATH = path self ./run-build.sh

export def main []: nothing -> nothing {
	print ""
	print "run-build-graphene"
	print "------------------\n"

	print "Updating source code"
	sync-graphene-source

	print "Starting build"
	build
}

def build []: nothing -> nothing {
	$PIXEL_BUILD_TARGETS
	| each {|pixelCodename|
		print $"Generating Pixel vendor files for ($pixelCodename)"
		timeit {
			adevtool generate-all -d $pixelCodename
		}
		| format duration min
		| print $"($pixelCodename) vendor file generation took ($in)"
	}

	$BUILD_TARGETS
	| each {|buildTarget|
		print $"Building GrapheneOS for ($buildTarget)"

		$env.BUILD_TARGET = $buildTarget
		$env.BUILD_VARIANT = $BUILD_VARIANT
		# Update path according to GrapheneOS build instructions for Debian
		$env.path ++= [
				"/sbin"
				"/usr/sbin"
				"/usr/local/sbin"
		]

		timeit {
			bash $RUN_BUILD_SCRIPT_PATH
		}
		| format duration min
		| print $"($buildTarget) build took ($in)"
	}
	| ignore
}
