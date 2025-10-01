use ./graphene-constants.nu *
use ($COMMON_CONSTANTS_PATH) *
use ($VM_SCRIPTS_CONSTANTS_PATH) *
use ($VM_SCRIPTS_UTIL_DIR)/perform-build-step.nu

export def main []: nothing -> nothing {
	cd $BUILD_ROOT_VM_DIR

	if $DOWNLOAD_STABLE {
		perform-build-step $"Initialize build dir for stable tag ($STABLE_TAG)" repo [
			"init"
			"-u"
			"https://github.com/GrapheneOS/platform_manifest.git"
			"-b"
			$"refs/tags/($STABLE_TAG)"
		]
		print $"Verifying tag signature"
		mkdir ~/.ssh
		curl https://grapheneos.org/allowed_signers | save -f ~/.ssh/grapheneos_allowed_signers
		cd .repo/manifests
		git config gpg.ssh.allowedSignersFile ~/.ssh/grapheneos_allowed_signers
		git verify-tag (git describe)
	} else {
		perform-build-step $"Initialize build dir for dev branch ($DEV_BRANCH)" repo [
			"init"
			"-u"
			"https://github.com/GrapheneOS/platform_manifest.git"
			"-b"
			$DEV_BRANCH
		]
	}

	let threads: int = (
		[
			(sys cpu | length)
			8
		]
		| math min
	)

	perform-build-step $"Sync source code with ($threads) threads" repo [
		"sync"
		"-j"
		$"($threads)"
		"--force-sync"
		"--verbose"
	]
}
