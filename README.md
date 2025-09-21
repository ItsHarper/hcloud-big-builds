## Setup

1. Create Google Cloud project named `GrapheneOS Builder`
2. Create low-power Compute Engine VM with Debian 12 (bookworm) named `source-downloader` (10 GB balanced persistent disk is fine)
3. Attach a second blank 100GB balanced persistent disk named `grapheneos-build-1` (must be kept on VM deletion)
4. Disable automatic restart
5. Boot the VM and run these commands
```bash
sudo useradd --create-home graphene
sudo usermod -aG google-sudoers graphene
sudo -u graphene -i
cd ~
git clone https://github.com/ItsHarper/GCP-GrapheneOS-build
```
6. Add the contents of `startup.sh` as a startup script: https://cloud.google.com/compute/docs/instances/startup-scripts/linux#passing-directly
7. Reboot the VM

## Troubleshooting

### Viewing logs

1. Go to https://console.cloud.google.com/logs/query
2. Run this query:
```
SEARCH("`startup-script:`")
```
