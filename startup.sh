#!/bin/bash
set -euo pipefail

# This script is intended to be a Compute Engine startup script:
# https://cloud.google.com/compute/docs/instances/startup-scripts/linux
#
# It will be run as root in that context

USERNAME=graphene

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
curl metadata.google.internal -i

echo "Updating GCP-GrapheneOS-build repository"
cd "/home/$USERNAME/GCP-GrapheneOS-build"
sudo -u $USERNAME git pull

echo "Starting run.sh"
sudo -u $USERNAME "/home/$USERNAME/GCP-GrapheneOS-build/run.sh"
