# Settings
export const DEV_BRANCH = "16"
export const STABLE_TAG = "2025092700"
export const DOWNLOAD_STABLE = true
export const BUILD_VARIANT = "userdebug"
export const PIXEL_BUILD_TARGETS = [
	# "oriole" # Pixel 6
	"bluejay" # Pixel 6a
	# "shiba" # Pixel 8
]
export const BUILD_TARGETS = [
	# "sdk_phone64_x86_64" # Emulator
	...$PIXEL_BUILD_TARGETS
]

# Other
export const GRAPHENE_COMMON_DIR = path self .
export const COMMON_CONSTANTS_PATH = path self ../../../../common/common-constants.nu
export const VM_SCRIPTS_CONSTANTS_PATH = path self ../../../util/vm-constants.nu

use ($COMMON_CONSTANTS_PATH) *
