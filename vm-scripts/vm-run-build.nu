#!/usr/bin/env nu

use std-rfc/iter
use ./util/vm-constants.nu *
use ./util/perform-build-step.nu *
use ./session-types/graphene-os/graphene-os-session-type.nu

def main [sessionTypeId: string]: nothing -> nothing {
	let sessionTypes: table<id: string, setUpVm: closure, prepareBuildRoot: closure, runBuild: closure> = [
		(graphene-os-session-type)
	];

	try {
		prepare-build-logs-dir

		let sessionType = (
			$sessionTypes
			| where id == $sessionTypeId
			| iter only
		)

		do $sessionType.setUpVm

		let runPreparation = not ($BUILD_ROOT_PREPARED_PATH | path exists)

		if $runPreparation {
			do $sessionType.prepareBuildRoot
			touch $BUILD_ROOT_PREPARED_PATH
			print "Finished preparing build root"
		}

		do $sessionType.runBuild $runPreparation
		print "Finished build"
	} catch {|e|
			print -e "Build failed:"
			print -e $e.rendered
			exit 1
	}
}
