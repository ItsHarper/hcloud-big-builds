use std-rfc/iter
use ../common/graphene-constants.nu *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu

export def main []: nothing -> nothing {
	print ""
	print "run-build-graphene"
	print "------------------\n"

	# Update path according to GrapheneOS build instructions
	$env.path ++= [
			"/sbin"
			"/usr/sbin"
			"/usr/local/sbin"
	]

	print "Updating source code"
	sync-graphene-source

	print "Starting build"
	build
}

def build []: nothing -> nothing {
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
