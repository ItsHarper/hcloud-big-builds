use ./util/vm-constants.nu *
use ./util/perform-build-step.nu *
use ./presets/graphene-os/run-build-graphene
use ./presets/graphene-os/set-up-vm-for-graphene.nu

try {
	set-up-vm-for-graphene
	prepare-build-logs-dir

	let runPreparation = not ($BUILD_ROOT_PREPARED_PATH | path exists)

	if $runPreparation {
		use ./presets/graphene-os/prepare-build-root-graphene
		prepare-build-root-graphene
		touch $BUILD_ROOT_PREPARED_PATH
		print "Finished preparing build root"
	}

	run-build-graphene $runPreparation
	print "Finished build"
} catch {|e|
	print -e "Build failed:"
	print -e $e.rendered
	exit 1
}
