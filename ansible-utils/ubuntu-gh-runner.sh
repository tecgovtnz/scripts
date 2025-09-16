#!/bin/bash

GITHUB_ORG_NAME=$1
GITHUB_APP_ID=$2
GITHUB_APP_PRIVATE_KEY_ENCODED=$3
ENVIRONMENT=$4

# Install the requirements for the GitHub authentication
sudo apt update
sudo apt install -y python3-pip
sudo apt install -y python3-github
sudo apt install -y docker.io
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
# pip3 install pygithub

# AZ CLI install
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

sudo apt-get -y update
sudo apt-get -y install azure-cli

sudo apt install -y pipx ansible-core

GITHUB_APP_PRIVATE_KEY=$(echo $GITHUB_APP_PRIVATE_KEY_ENCODED | base64 --decode) 
# Generate the github runner registration token 
ACCESS_TOKEN=$(python3 github_app_token.py -o $GITHUB_ORG_NAME -a $GITHUB_APP_ID -p "$GITHUB_APP_PRIVATE_KEY")
# Generate the GitHub runner token
response=$(curl -X POST \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/orgs/$GITHUB_ORG_NAME/actions/runners/registration-token")

# Extract the token from the response
TOKEN=$(echo "$response" | jq -r '.token')

#create directory
mkdir /opt/runner-cache

#change directory
cd /opt/runner-cache

#download latest release
curl -s https://api.github.com/repos/actions/runner/releases/latest | grep browser_download_url | grep 'actions-runner-linux-x64' | head -n 1 | cut -d '"' -f 4 | wget -i -

#extract release
tar xzf ./actions-runner-linux-x64-*.*.*.tar.gz

# Install Github runner agent
useradd -d /opt/runner-cache action-runner
usermod -aG sudo action-runner
chown action-runner /opt/runner-cache --recursive
chgrp action-runner /opt/runner-cache --recursive

# Extract the installer
tar xzf ./actions-runner-linux*.tar.gz


# Create the runner and start the configuration experience
 export RUNNER_ALLOW_RUNASROOT=1

 if [[ "$ENVIRONMENT" == "dev" || "$ENVIRONMENT" == "dev-testing" || "$ENVIRONMENT" == "dev-platform" || "$ENVIRONMENT" == "dev-platform-testing" ]]; then
    RUNNER_NAME=$(hostname)-$ENVIRONMENT
elif [[ "$ENVIRONMENT" == "prod-platform" ]]; then
    RUNNER_NAME=$(hostname)-platform
elif [[ "$ENVIRONMENT" == "prod-testing" ]]; then
    RUNNER_NAME=$(hostname)-testing
elif [[ "$ENVIRONMENT" == "prod-testing-platform" ]]; then
    RUNNER_NAME=$(hostname)-testing-platform
else
    RUNNER_NAME=$(hostname)
fi

 ./config.sh --url https://github.com/tecgovtnz --token $TOKEN --runasservice --name $RUNNER_NAME --work _work --runnergroup $ENVIRONMENT --labels $ENVIRONMENT,$HOSTNAME
# install as a service account


# change owner and group again due to there are some file update after run config.sh
chown action-runner /opt/runner-cache --recursive
chgrp action-runner /opt/runner-cache --recursive

# Add runner user to docker group
sudo usermod -aG docker action-runner

#set path for action-runner user
echo '/snap/bin:/home/action-runner/.local/bin:/opt/pipx_bin:/home/action-runner/.cargo/bin:/home/action-runner/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/action-runner/.dotnet/tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin' > /opt/runner-cache/.path

# Install ansible collections and requirements
sudo rm -rf $(echo "/opt/pipx/venvs/ansible-core/lib/python3.1"*"/site-packages/ansible_collections/azure") # Delete existing azure collection
sudo rm -rf $(echo "/opt/pipx/venvs/ansible-core/lib/python3.1"*"/site-packages/ansible_collections/ansible/windows") # Delete existing windows collection
sudo su - action-runner -c "ansible-galaxy collection install ansible.windows:==2.4.0 azure.azcollection:==2.3.0" # Pin older collection versions
sudo su - action-runner -c "cat /opt/runner-cache/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt | sed -e 's/#.*//' | xargs pipx inject ansible-core"
sudo su - action-runner -c "pipx inject ansible-core pywinrm jmespath pygithub setuptools"
pip install PyGithub

# Set docker registry mirror 'https://cloud.google.com/artifact-registry/docs/pull-cached-dockerhub-images#cli'
printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
sudo service docker restart

./svc.sh install action-runner
# Last step, run it!
./svc.sh start
./svc.sh status
