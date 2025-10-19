#!/usr/bin/env nu

use std-rfc/iter
use ./util/vm-constants.nu *
use ./util/perform-build-step.nu *
use ./session-types/graphene-os/graphene-os-session-type.nu

def main [sessionTypeId: string]: nothing -> nothing {
	let sessionTypes: table<id: string, setUpVm: closure, prepareBuildRoot: closure, runBuild: closure> = [
		(graphene-os-session-type)
		{
			id: "test-only"
			setUpVm: { print "setUpVm (no-op)" }
			prepareBuildRoot: { print "prepareBuildRoot (no-op)" }
			runBuild: { print "runBuild (no-op)" }
		}
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
			print "\nFinished preparing build root"
		}

		do $sessionType.runBuild $runPreparation
		print "\nFinished build"
	} catch {|e|
			print -e "\nBuild failed:"
			print -e $e.rendered
			exit 1
	}
}
