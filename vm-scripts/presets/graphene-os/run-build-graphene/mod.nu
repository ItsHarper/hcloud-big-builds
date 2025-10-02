use ../common/graphene-constants.nu *
use ($GRAPHENE_COMMON_DIR)/sync-graphene-source.nu
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu

const RUN_BUILD_SCRIPT_PATH = path self ./run-build.sh

export def main []: nothing -> nothing {
	sync-graphene-source # TODO(Harper): Skip if we just did this
	build
}

def build []: nothing -> nothing {
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
