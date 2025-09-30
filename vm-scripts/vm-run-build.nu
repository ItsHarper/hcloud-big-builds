use vm-constants.nu *
use ./presets/graphene-os/run-build-graphene

try {
	if not ($BUILD_ROOT_PREPARED_PATH | path exists) {
		error make { msg: $"The build root has not yet been prepared" }
	}

	run-build-graphene
} catch {|e|
	print -e "vm-run-build.nu failed:"
	print -e $e.rendered
	print -e "Shutting down VM in 5 minutes"
	sudo shutdown +5
	exit 1
}
