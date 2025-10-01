use std-rfc/iter
use ../common/graphene-constants.nu *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu

const GENERATE_PIXEL_VENDOR_FILES_SCRIPT_PATH = path self ./generate-pixel-vendor-files.sh
const RUN_BUILD_SCRIPT_PATH = path self ./run-build.sh

export def main []: nothing -> nothing {
	sync-graphene-source
	build
}

def build []: nothing -> nothing {
	$PIXEL_BUILD_TARGETS
	| each {|pixelCodename|
		$env.BUILD_TARGET = $pixelCodename
		$env.BUILD_VARIANT = $BUILD_VARIANT
		perform-build-step $"Generate Pixel vendor files for ($pixelCodename)" bash [
			$GENERATE_PIXEL_VENDOR_FILES_SCRIPT_PATH
		]
	}

	$BUILD_TARGETS
	| each {|buildTarget|
		$env.BUILD_TARGET = $buildTarget
		$env.BUILD_VARIANT = $BUILD_VARIANT
		# Update path according to GrapheneOS build instructions for Debian
		$env.path ++= [
				"/sbin"
				"/usr/sbin"
				"/usr/local/sbin"
		]

		perform-build-step $"Build GrapheneOS for ($buildTarget)" bash [
			$RUN_BUILD_SCRIPT_PATH
		]
	}
	| ignore
}
