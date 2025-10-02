use ../common/graphene-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu

const PREPARE_PIXEL_FILES_SCRIPT_PATH = path self ./prepare-for-pixel-vendor-files-generation.sh
const GENERATE_PIXEL_VENDOR_FILES_SCRIPT_PATH = path self ./generate-vendor-files-for-pixel.sh

export def main []: nothing -> nothing {
	sync-graphene-source
	generate-pixel-vendor-files
}

def generate-pixel-vendor-files []: nothing -> nothing {
	perform-build-step "Prepare for generation of Pixel vendor files" bash [
		$PREPARE_PIXEL_FILES_SCRIPT_PATH
	]

	$PIXEL_BUILD_TARGETS
	| each {|pixelCodename|
		$env.PIXEL_CODENAME = $pixelCodename
		perform-build-step $"Generate vendor files for Pixel: ($pixelCodename)" bash [
			$GENERATE_PIXEL_VENDOR_FILES_SCRIPT_PATH
		]
	}
	null
}
