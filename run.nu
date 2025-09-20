use std-rfc/iter

print ""
print "run.nu"
print "------\n"

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
http --full metadata.google.internal
| get headers
| get response
| where name == "metadata-flavor" and value == "Google"
| iter only

let buildDiskPaths = (
	ls --full-paths /dev/disk/by-id/
	| get name
	| find --regex `google-grapheneos-build-\d+$`
)

$buildDiskPaths
| each {|diskPath|
	let diskLinkTarget = ls -l --directory --full-paths $diskPath | get target
	let diskParts = ls --full-paths (($diskPath)-part* | into glob)
	if ($diskParts | length) == 0 {
		# This disk needs formatting
		# https://cloud.google.com/compute/docs/disks/format-mount-disk-linux
		sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $diskLinkTarget
	}
}
