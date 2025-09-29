use std-rfc/iter
use ../common/graphene-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu
use ($GRAPHENE_COMMON_DIR)/set-up-vm-for-graphene.nu

const PREPARE_PIXEL_FILES_SCRIPT_PATH = path self ./prepare-for-pixel-vendor-files-generation.sh

export def main []: nothing -> nothing {
	print ""
	print "prepare-build-root-graphene"
	print "---------------------------\n"

	set-up-vm-for-graphene

	print "Downloading source code"
	sync-graphene-source

	print "Preparing for pixel vendor files generation"
	prepare-for-pixel-vendor-files-generation
}

def prepare-for-pixel-vendor-files-generation []: nothing -> nothing {
	cd $BUILD_ROOT_VM_DIR
	bash $PREPARE_PIXEL_FILES_SCRIPT_PATH
}
