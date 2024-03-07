#!/bin/bash

# install requirements for runner registration
pip3 install -r requirements.txt

# install ansible collections
ansible-galaxy collection install -p '/opt/pipx/venvs/ansible-core/lib/python3.1*/site-packages/ansible_collections' -r collection-requirements.yml --force

