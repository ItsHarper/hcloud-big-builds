use ./util/vm-constants.nu *
use ./util/perform-build-step.nu *
use ./presets/graphene-os/run-build-graphene
use ./presets/graphene-os/set-up-vm-for-graphene.nu

try {
	set-up-vm-for-graphene
	prepare-build-logs-dir

	if not ($BUILD_ROOT_PREPARED_PATH | path exists) {
		use ./presets/graphene-os/prepare-build-root-graphene
		prepare-build-root-graphene
		touch $BUILD_ROOT_PREPARED_PATH
		print "Finished preparing build root"
	}

	run-build-graphene
	print "Finished build"
	print "Shutting down VM"
	sudo shutdown now
} catch {|e|
	print -e "vm-run-build.nu failed:"
	print -e $e.rendered
	print -e "Shutting down VM in 5 minutes"
	print -e "Cancel using `atrm <jobNumber>` (the job number will be listed below)"
	# We're using at instead of the functionality built into shutdown to make sure logins continue to be allowed
	"sudo shutdown now" | at now + 5 minutes
	exit 1
}
