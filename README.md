## Setup

1. Create Google Cloud project named `GrapheneOS Builder`
2. Create low-power Compute Engine VM named `source-downloader`
  * Debian 12 (bookworm)
  * 10 GB balanced persistent boot disk
  * Additional 275GB balanced persistent disk named `grapheneos-build-<num>`
  * Automatic restart off (Advanced tab)
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
3. Disable automatic restart
4. Boot the VM and run these commands
```bash
sudo useradd --create-home graphene
sudo usermod -aG google-sudoers graphene
sudo -u graphene -i
cd ~
git clone https://github.com/ItsHarper/GCP-GrapheneOS-build
```
5. Edit `/etc/apt/sources.list.d/debian.sources` so that `contrib` is included in the `Components:` list of both repos
6. Add the contents of `startup.sh` as a startup script: https://cloud.google.com/compute/docs/instances/startup-scripts/linux#passing-directly
7. Reboot the VM

## Troubleshooting

### Viewing logs

1. Go to https://console.cloud.google.com/logs/query
2. Run this query:
```
SEARCH("`startup-script:`")
```

## TODO

* It's probably a better play to just change the VM type in between download and first build
  than to use two separate VMs
