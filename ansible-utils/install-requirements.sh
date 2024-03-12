#!/bin/bash

#sudo apt-get update
#sudo apt install -y python3-github
#sudo apt install -y python-argparse


# install requirements for runner registration
# pip3 install -r requirements.txt

USR1=ZadockAllen
PATH=/snap/bin:/home/$USR1/.local/bin:/opt/pipx_bin:/home/$USR1/.cargo/bin:/home/$USR1/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/$USR1/.dotnet/tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/$USR1/.dotnet/tools

echo $PATH
python --version
env
ansible --version


installpath=$(echo "/opt/pipx/venvs/ansible-core/lib/python3.1"*"/site-packages/ansible_collections")
patharray=($installpath)


# install ansible collections
ansible-galaxy collection install -p ${patharray[1]} -r collection-requirements.yml --force
ansible-galaxy collection install
