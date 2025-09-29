# Settings
export const DEV_BRANCH = "16"
export const STABLE_TAG = "2025091000"
export const DOWNLOAD_STABLE = true
export const PIXEL_DEVICES_TO_BUILD = [
	"shiba"
]

# Other
export const GRAPHENE_COMMON_DIR = path self .
export const COMMON_CONSTANTS_PATH = path self ../../../../common/common-constants.nu

use ($COMMON_CONSTANTS_PATH) *
