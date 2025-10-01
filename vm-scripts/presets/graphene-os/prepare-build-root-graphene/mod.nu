use std-rfc/iter
use ../common/graphene-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu

const PREPARE_PIXEL_FILES_SCRIPT_PATH = path self ./prepare-for-pixel-vendor-files-generation.sh

export def main []: nothing -> nothing {
	sync-graphene-source
	prepare-for-pixel-vendor-files-generation
}

def prepare-for-pixel-vendor-files-generation []: nothing -> nothing {
	perform-build-step "Prepare for generation of pixel vendor files" bash [
		$PREPARE_PIXEL_FILES_SCRIPT_PATH
	]
}
