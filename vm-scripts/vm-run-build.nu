use vm-constants.nu *
use ./presets/graphene-os/run-build-graphene

if not ($BUILD_ROOT_PREPARED_PATH | path exists) {
	error make { msg: $"The build root has not yet been prepared" }
}

run-build-graphene
