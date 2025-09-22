use ../common/constants.nu *

export def sync-source [buildDir: string]: nothing -> nothing {
	cd $buildDir

	if $DOWNLOAD_STABLE {
		print $"Initializing ($buildDir) for stable tag ($STABLE_TAG)"
		repo init -u https://github.com/GrapheneOS/platform_manifest.git -b refs/tags/($STABLE_TAG)
		mkdir ~/.ssh
		curl https://grapheneos.org/allowed_signers | save ~/.ssh/grapheneos_allowed_signers
		cd .repo/manifests
		git config gpg.ssh.allowedSignersFile ~/.ssh/grapheneos_allowed_signers
		git verify-tag (git describe)
		cd ../..
	} else {
		print $"Initializing ($buildDir) for dev branch ($DEV_BRANCH)"
		repo init -u https://github.com/GrapheneOS/platform_manifest.git -b $DEV_BRANCH
	}

	print "Syncing source code"
	repo sync -j8 --force-sync
}
