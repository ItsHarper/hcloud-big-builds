export const TOP_LEVEL_COMMON_DIR = path self .
export const HCLOUD_BB_LOCAL_DIR = path self ..
export const VM_SCRIPTS_DIR = path self ../vm-scripts
export const VM_CONFIG_DIR = path self ../vm-config

export const VM_USERNAME = "builder"

export const BUILD_ROOT_VM_DIR = "/mnt/build-root"
export const HCLOUD_BB_VM_DIR = $"/home/($VM_USERNAME)/hcloud-bb"
export const RUN_NUSHELL_SCRIPT_VM_PATH = $"($HCLOUD_BB_VM_DIR)/vm-scripts/run-nushell-script.sh"

# GrapheneOS constants
export const GRAPHENE_PIXEL_BUILD_TARGETS = [
	# "oriole" # Pixel 6
	"bluejay" # Pixel 6a
	# "shiba" # Pixel 8
]
export const GRAPHENE_BUILD_TARGETS = [
	# "sdk_phone64_x86_64" # Emulator
	...$GRAPHENE_PIXEL_BUILD_TARGETS
]
