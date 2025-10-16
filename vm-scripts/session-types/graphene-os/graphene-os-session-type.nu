use ./prepare-build-root-graphene
use ./run-build-graphene
use ./set-up-vm-for-graphene.nu

export def main []: nothing -> record {
	{
		id: "graphene-os"
		setUpVm: {
			set-up-vm-for-graphene
		}
		prepareBuildRoot: {
			prepare-build-root-graphene
		}
		runBuild: {|preparationJustRan|
			run-build-graphene $preparationJustRan
		}
	}
}
