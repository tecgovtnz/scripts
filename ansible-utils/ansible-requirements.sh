#!/bin/bash

# Install ansible collections and requirements
sudo rm -rf $(echo "/opt/pipx/venvs/ansible-core/lib/python3.1"*"/site-packages/ansible_collections/azure") # Delete existing azure collection
sudo su - action-runner -c "ansible-galaxy collection install azure.azcollection"
sudo su - action-runner -c "ansible-galaxy collection install ansible.windows"
sudo su - action-runner -c "pip3 install -r /opt/runner-cache/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt"
sudo su - action-runner -c "pip3 install pywinrm"
