use vm-constants.nu *
use ./presets/graphene-os/prepare-build-root-graphene

prepare-build-root-graphene

touch $BUILD_ROOT_PREPARED_PATH
print "Finished preparing build root"
