## 🚧 WIP

This software is not yet ready for general use

## `hcloud-bb`

`hcloud-bb` makes building large software projects on Hetzner Cloud easy, fast, and inexpensive.
Builds are performed on storage that is not tied to a specific VM, so once a build has finished
and the VM is about to be billed for another hour, it can be automatically deleted.

Meanwhile, the full build folder can be preserved indefinitely, enabling fast incremental builds.

### TODO

* Use labels instead of assuming that anything in the project we don't know about can be deleted
* Use long-running service for pruning instead of relying on an external cron job
* Add hcloud firewall to created VMs
* Use containers to perform the actual build
	* We can provide some pre-made containers that accept environment variables for source location, auth token, etc
	* Machine type can be configured separately for the setup container and the build container
* Beyond making it easy for people to build GrapheneOS and Vanadium, the obvious next place to take this is OpenDroid, a next-gen F-Droid alternative.
