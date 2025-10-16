use ../common/graphene-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu

const RUN_BUILD_SCRIPT_PATH = path self ./run-build.sh

export def main [preparationJustRan: bool]: nothing -> nothing {
	if not $preparationJustRan {
		sync-graphene-source
	}
	build
}

def build []: nothing -> nothing {
	$GRAPHENE_BUILD_TARGETS
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
