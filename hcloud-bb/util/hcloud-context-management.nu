use ./hcloud-bb-constants.nu *
use hcloud-wrapper.nu *

export def set-up-hcloud-context []: nothing -> nothing {
	let activeContext = (hcloud context active)
	if $activeContext == "" {
		print "When prompted, provide a read/write API token for the appropriate Hetzner Cloud project"
		hcloud context create $CONTEXT_NAME
	}
}
