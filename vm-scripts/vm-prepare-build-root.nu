use vm-constants.nu *
use ./presets/graphene-os/prepare-build-root-graphene

try {
	prepare-build-root-graphene

	touch $BUILD_ROOT_PREPARED_PATH
	print "Finished preparing build root"
} catch {|e|
	print -e "vm-prepare-build-root.nu failed:"
	print -e $e.rendered
	print -e "Shutting down VM in 5 minutes"
	sudo shutdown +5
	exit 1
}
