#!/bin/bash
# This file should be sourced

# Change directory to user home
cd ~

# Upgrade all packages that have available updates and remove old ones.
sudo apt-get update
sudo apt upgrade -y
sudo apt autoremove --assume-yes

# Install git
sudo apt install git --assume-yes

# Install azcli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install venv and pip
sudo apt install python3-venv --assume-yes
sudo apt install python3-pip --assume-yes

# Setup virtual environment and push home folder ownership
sudo python3 -m venv venv
sudo chown ZadockAllen /home/ZadockAllen --recursive

# # Install ansible and azure modules into virtual environment
# pip3 install -r https://sautilscript.blob.core.windows.net/githubrunner/requirements.txt

wget https://files.pythonhosted.org/packages/f0/e2/f8b4f1c67933a4907e52228241f4bd52169f3196b70af04403b29c63238a/pyOpenSSL-23.2.0-py3-none-any.whl
python3 -m easy_install pyOpenSSL-23.2.0-py3-none-any.whl