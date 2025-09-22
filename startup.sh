#!/bin/bash
set -euo pipefail

# This script is intended to be a Compute Engine startup script:
# https://cloud.google.com/compute/docs/instances/startup-scripts/linux
#
# It will be run as root in that context

USERNAME=graphene
SCRIPTS_DIR="/home/$USERNAME/GCP-GrapheneOS-build"
SCRIPTS_REPO_URL="https://github.com/ItsHarper/GCP-GrapheneOS-build"

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
curl metadata.google.internal -i

if [[ ! -d $SCRIPTS_DIR ]]; then
	echo "Performing one-time setup"
	apt-get -y install git
	# contrib repository is needed so that the nushell scripts can install `repo`
	add-apt-repository --component contrib
	useradd --create-home --shell /bin/bash $USERNAME
	usermod -aG google-sudoers $USERNAME
	sudo -u $USERNAME git clone "$SCRIPTS_REPO_URL" "$SCRIPTS_DIR"
fi

echo "Updating scripts repository"
cd $SCRIPTS_DIR
sudo -u $USERNAME git pull

echo "Starting run.sh"
sudo -u $USERNAME "$SCRIPTS_DIR/run.sh"
