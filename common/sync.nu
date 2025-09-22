use ../common/graphene-constants.nu *

export def sync-source [buildDir: string]: nothing -> nothing {
	cd $buildDir

	timeit {
		if $DOWNLOAD_STABLE {
			print $"Initializing ($buildDir) for stable tag ($STABLE_TAG)"
			repo init -u https://github.com/GrapheneOS/platform_manifest.git -b refs/tags/($STABLE_TAG)
			mkdir ~/.ssh
			curl https://grapheneos.org/allowed_signers | save -f ~/.ssh/grapheneos_allowed_signers
			cd .repo/manifests
			git config gpg.ssh.allowedSignersFile ~/.ssh/grapheneos_allowed_signers
			git verify-tag (git describe)
			cd ../..
			null
		} else {
			print $"Initializing ($buildDir) for dev branch ($DEV_BRANCH)"
			repo init -u https://github.com/GrapheneOS/platform_manifest.git -b $DEV_BRANCH
			null
		}
	}
	| format duration min
	| print $"repo initialization took ($in)"

	let threads = (
		[
			sys cpu | length
			8
		]
		| math min
	)

	print ""
	print $"Syncing source code with ($threads) threads"
	print "-------------------"
	timeit {
		repo sync -j8 --force-sync --verbose out>sync-log.txt
	}
	| format duration min
	| print $"repo sync took ($in)"
	null
}
