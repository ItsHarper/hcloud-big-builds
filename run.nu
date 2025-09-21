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

# TODO(Harper): We may not need to list the parts
let buildDiskAndPartitionDevs = (
	ls --long --full-paths /dev/disk/by-id/
	| where name =~ "google-grapheneos-build-"
	| insert is-part {|listing| $listing.name =~ "part" }
)

let buildDisks = (
	$buildDiskAndPartitionDevs
	| where is-part == false
	| each {|diskDev|
		let name = $diskDev | get name | parse --regex '.*(?<name>google-grapheneos-build-\d+)' | get name
		let partitions = (
			$buildDiskAndPartitionDevs
			| where ($it.name =~ $diskDev.name) and $it.is-part
		)
		{ name: $name, diskDev: ($diskDev | reject is-part), partitions: ($partitions | reject is-part) }
	}
)

$buildDisks
| each {|disk|
	let diskLinkTarget = $disk.diskDev | get target
	let blkIdResult = sudo blkid $diskLinkTarget | complete
	let needsFormatting = ($blkIdResult.exit_code != 0) or not ($blkIdResult.stdout =~ 'TYPE="EXT4"')
	if $needsFormatting {
		# This disk needs formatting
		# https://cloud.google.com/compute/docs/disks/format-mount-disk-linux
		sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $diskLinkTarget

		print "Rebooting in 5 seconds, so that the partition symlinks get created"
		sleep 5sec
		sudo reboot

		# Don't capture the output of the previous command
		null
	}

	let mountPoint = /mnt/disks/($disk.name)
	sudo mkdir -p $mountPoint
	sudo mount -o discard,defaults $diskLinkTarget $mountPoint
}
