#!/bin/bash
# This file should be sourced
mkdir /home/action-runner
sudo chown action-runner /home/action-runner --recursive
sudo chgrp action-runner /home/action-runner --recursive
sudo useradd -d /home/action-runner action-runner

# Change directory to user home
cd /home/action-runner

# Install Github runner agent
# Create a folder
mkdir actions-runner && cd actions-runner
# Download the latest runner package
curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz
# Optional: Validate the hash
echo "292e8770bdeafca135c2c06cd5426f9dda49a775568f45fcc25cc2b576afc12f  actions-runner-linux-x64-2.304.0.tar.gz" | shasum -a 256 -c
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz

# Create the runner and start the configuration experience
./config.sh --url https://github.com/tecdevgovtnz --token A6KCUSTOR3GRTA2A3W7V55LEQ7AZE --runasservice --runnergroup local-runner --unattended
#install as a service account
./svc.sh install action-runner
# Last step, run it!
sudo ./svc.sh start
sudo ./svc.sh status
#./run.sh

cd ~
