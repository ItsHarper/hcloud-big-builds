## High level architecture options

The current plan is to go straight to Hetzner instead of continuing to do perf
analysis in GCP first. Keep reading for why Hetzner's offering seems like such
a great fit.

* GCP (tortoise strategy)
	* Only fast enough if we always keep storage allocated
	* Constant storage allocation means high fixed costs
* GCP (hare strategy)
	* All persistent storage types are high-latency
	* Only temporary storage is fast enough to actually build from
	* Spot VM isn't viable without persistent storage, so we'd have to pay full price for compute
	* Two sub-options
		* Every build costs the full amount
			* I suspect this would cost well over the max target $1 per build
		* Store data to Google Cloud Storage between builds
			* Enables Very Flexible Pricing scheme (GCP)
				* One-off build: $`X`
				* Batch of builds: $`X + (hours * 0.011) + (?? * builds)`
			* Adds complexity
			* Has a performance penalty
			* May be complicated to implement in a way that's performant enough to make sense
			* Incremental builds may be slow enough to make VFP too expensive (`??` in the formula)
* Hetzner
	* Enables Very Flexible Pricing scheme (Hetzner)
		* One-off build: $`Y` (almost certainly much cheaper than GCP's `X`)
		* Batch of builds: $`Y + (hours * 0.0306)`
	* Builds are done on high-performance VMs, probably their top tier
	* Build directory is located on Block Storage volume
		* Should be low-latency enough to run the build directly on it
		* Can be detached from the VM and persist after the VM is destroyed
	* Very simple
	* The cost to do an incremental build will hopefully be low enough to ignore
	* Should enable the holy grail: cheap, reasonably fast initial build, extremely fast incremental builds

## TODO

* Use containers for everything not entirely tied to hcloud-bb
	* User provides build container and setup container
	* When setup container fails, volume is marked as not-for-use (but kept for a period of time to allow troubleshooting)
	* We can provide some pre-made setup containers that accept environment variables for source location, auth token, etc
	* Machine type can be configured separately for the setup container and the build container
		* Extremely low priority. Hetzner charges by the hour, so this would only make sense if your setup
		  process is slow regardless of what hardware it's running on
* Allow configuring minimum time that the server is kept alive after a build
* Beyond making it easy for people to build GrapheneOS, the obvious next place to take this is OpenDroid, a next-gen F-Droid alternative.

## Older notes on performance tiers and such

* I've been thinking about this from a "start low-end and test scaling up"
  perspective, but in most cases you're going to be doing builds over a
  significant period of time, and if you're relying on pre-downloaded data
  and incremental builds to make that economical, you're going to have high
  costs for storage, that can be extra-costly if you make a bad call about
  when to clear it out.

* The holy grail is making a 100% fresh build so fast that extremely
  expensive hardware becomes affordable, and then in Google Cloud, you get
  storage that is both low-latency and cheap (using a RAM disk may even make
  sense). I should start by seeing if this is viable.

* I think the source code download is probably the least-scalable part. Let's
  start by testing how fast it can download to a RAM disk.

* e2-highcpu-8 is maxing out the CPU, and has plenty of spare RAM capacity
  (though the RAM is full of cached data). At very low tiers, much of the
  cost is the boot disk, and we can delete the whole VM once the initial
  download is complete. I think it makes a good amount of sense to bump
  up the tier until the performance gains peter out (keeping in mind that
  we only allow up to 8 threads for `repo sync`).

* CPU utilization was shockingly high on c4-highmem-24 with a RAM disk and 8 sync jobs.
  Perhaps source code syncing could scale better than I assumed.

* The `prepare-for-pixel-vendor-files-generation` script caused the system to run out of RAM because of the RAM disk,
  but the actual download process took about 22 minutes. If using a local SSD instead of a RAM disk doesn't hurt that too
  much, that's not _too_ bad (about 65 cents of non-interruptible compute time). On Hetzner that amount of  time would cost
  just 17 cents, and that's for a much more powerful server. So we're still in the realm of feasible for the hurry-up-and-delete
  approach, as long as losing the RAM disk doesn't kill us.

## Setup instructions for original GCP prototype

1. Create Google Cloud project named `GrapheneOS Builder`
2. Create low-power Compute Engine VM named `source-downloader`
  * Debian 13 (trixie)
  * Default boot disk configuration
  * Copy `startup.sh` contents into `Startup script` field (Advanced tab)
  * MAYBE NOT: Automatic restart off (Advanced tab)
  * MAYBE NOT: Additional 275GB balanced persistent disk named `grapheneos-build-<num>`
