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

let buildDisksAndPartitions = (
	ls --long --full-paths /dev/disk/by-id/
	| where name =~ "google-grapheneos-build-"
	| insert is-part {|listing| $listing.name =~ "part" }
)

let buildDisks = (
	$buildDisksAndPartitions
	| where is-part == false
	| each {|buildDiskListing|
		let partitions = (
			$buildDisksAndPartitions
			| where ($it.name =~ $buildDiskListing.name) and $it.is-part
		)
		{ disk: $buildDiskListing, partitions: $partitions }
	}
)

$buildDisks
| each {|disk|
	let diskLinkTarget = $disk.disk | get target
	if ($disk.partitions | length) == 0 {
		# This disk needs formatting
		# https://cloud.google.com/compute/docs/disks/format-mount-disk-linux
		sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $diskLinkTarget
	}
}
