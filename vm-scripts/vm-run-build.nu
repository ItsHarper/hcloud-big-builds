use vm-constants.nu *
use ./presets/graphene-os/run-build-graphene

try {
	if not ($BUILD_ROOT_PREPARED_PATH | path exists) {
		use ./presets/graphene-os/prepare-build-root-graphene
		prepare-build-root-graphene
		touch $BUILD_ROOT_PREPARED_PATH
		print "Finished preparing build root"
	}

	run-build-graphene
	print "Finished build"
} catch {|e|
	print -e "vm-run-build.nu failed:"
	print -e $e.rendered
	print -e "Shutting down VM in 5 minutes"
	sudo shutdown +5
	exit 1
}
