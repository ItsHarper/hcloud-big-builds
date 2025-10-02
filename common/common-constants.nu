export const TOP_LEVEL_COMMON_DIR = path self .
export const VM_SCRIPTS_DIR = path self ../vm-scripts
export const VM_CONFIG_DIR = path self ../vm-config

export const VM_USERNAME = "builder"

export const BUILD_ROOT_VM_DIR = "/mnt/build-root"
export const HCLOUD_BB_VM_DIR = $"/home/($VM_USERNAME)/hcloud-bb"
export const RUN_NUSHELL_SCRIPT_VM_PATH = $"($HCLOUD_BB_VM_DIR)/vm-scripts/run-nushell-script.sh"
