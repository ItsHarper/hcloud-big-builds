use std-rfc/iter

export def get-build-disk-symlinks []: nothing -> table {
	# Wildcards error out if no matching results are found,
	# so we do a complete listing and perform filtering
	ls --long --full-paths /dev/disk/by-id/
	| rename --column { name: "path" }
	# We don't care about the partitions (if any)
	# Keep string in sync with regex in build-disk-name-from-symlink-path
	| where $it.path =~ "google-grapheneos-build-" and not ($it.path =~ "part")
}

# Accepts output from a table entry from get-build-disk-symlinks as input
def get-mountpoint-path [symlinkRecord: record<path: string>]: nothing -> string {
	let name = (
		$symlinkRecord
		| get path
		# Keep regex in sync with string in get-build-disk-symlinks
		| parse --regex 'google-(?<name>grapheneos-build-\d+)'
		| iter only
		| get name
	)
	$"/mnt/disks/($name)"
}

# Accepts output from get-build-disk-symlinks as input
# Returns list of build disk mountpoints
export def mount-build-disks []: table -> list<string> {
	each {|diskSymlink|
		let mountpointPath = get-mountpoint-path $diskSymlink
		if (mountpoint $mountpointPath | complete | get exit_code) != 0 {
			print $"Mounting ($mountpointPath)"
			sudo mkdir -p $mountpointPath
			sudo mount -o discard,defaults $diskSymlink.target $mountpointPath
			null
		} else {
			print $"Verified mountpoint at ($mountpointPath)"
		}

		$mountpointPath
	}
}
