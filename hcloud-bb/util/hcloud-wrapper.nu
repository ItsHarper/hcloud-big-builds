use ./hcloud-bb-constants.nu *

const HCLOUD_VERSION = "1.52.0"

# Run pinned version of hcloud
export def --wrapped hcloud [...rest]: nothing -> string {
	let hcloudPath = get-hcloud-path

	if not ($hcloudPath | path exists) or (run-external $hcloudPath "version") != $"hcloud ($HCLOUD_VERSION)" {
		# TODO(Harper): Package nu_plugin_compress for Chimera Linux
		error make { msg: "`hcloud` download code is currently disabled" }
		# plugin use compress

		# let hcloudDir = get-hcloud-dir
		# mkdir $hcloudDir
		# cd $hcloudDir

		# print $"Downloading hcloud ($HCLOUD_VERSION)"
		# http $"https://github.com/hetznercloud/cli/releases/download/v($HCLOUD_VERSION)/hcloud-linux-amd64.tar.gz"
		# | from gz
		# | tar xf -
	}

	run-external $hcloudPath "--config" $"(get-config-dir)/($HCLOUD_CONFIG_FILENAME)" ...$rest
}

def get-hcloud-dir []: nothing -> string {
	(get-state-dir)/hcloud
}

def get-hcloud-path []: nothing -> string {
	(get-hcloud-dir)/hcloud
}
