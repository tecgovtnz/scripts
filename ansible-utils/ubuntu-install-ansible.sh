#!/bin/bash
# This file should be sourced

# Upgrade all packages that have available updates and remove old ones.
sudo apt-get update
sudo apt upgrade -y
sudo apt autoremove --assume-yes

# update python 3.11
sudo apt install build-essential checkinstall libreadline-gplv2-dev  libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.11
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Install git
sudo apt install git --assume-yes
sudo apt install -y jq

# Install azcli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install venv and pip
sudo apt install python3-venv --assume-yes
sudo apt install python3-pip --assume-yes

# Setup virtual environment and push home folder ownership
sudo python3 -m venv venv
sudo chown ZadockAllen /home/ZadockAllen --recursive

# Install ansible and azure modules into virtual environment
pip3 install -r requirements.txt

ansible-galaxy collection install community.general --force
ansible-galaxy collection install microsoft.ad --force

wget https://files.pythonhosted.org/packages/f0/e2/f8b4f1c67933a4907e52228241f4bd52169f3196b70af04403b29c63238a/pyOpenSSL-23.2.0-py3-none-any.whl
python3 -m easy_install pyOpenSSL-23.2.0-py3-none-any.whl
