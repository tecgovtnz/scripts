#!/bin/bash

GITHUB_ORG_NAME=$1
GITHUB_APP_ID=$2
GITHUB_APP_PRIVATE_KEY_ENCODED=$3
ENVIRONMENT=$4

# Install the requirements for the GitHub authentication
sudo apt-get update
sudo apt-get install -y python3-pip python3-github docker.io apt-transport-https ca-certificates curl gnupg lsb-release pipx zip unzip 

# AZ CLI install
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

source /etc/os-release
# AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${VERSION_CODENAME}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

wget -q "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm -f /tmp/packages-microsoft-prod.deb

sudo apt-get -y update
sudo apt-get -y install azure-cli powershell gh

# Install Az PowerShell module for all users
sudo pwsh -NoLogo -NoProfile -Command "Install-PSResource -Name Az -Repository PSGallery -TrustRepository -Scope AllUsers"

# sudo apt-get -y update
# sudo apt-get -y install 

# Install Powershell

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

#set path for action-runner user - must match the useradd -d home dir (/opt/runner-cache), not the default /home/action-runner
echo '/snap/bin:/opt/runner-cache/.local/bin:/opt/pipx_bin:/opt/runner-cache/.cargo/bin:/opt/runner-cache/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/opt/runner-cache/.dotnet/tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin' > /opt/runner-cache/.path

# Install ansible collections and requirements (current versions)
# ansible-galaxy/pipx shims live in ~/.local/bin which isn't on PATH for a plain login shell, so export .path first or these fail silently
# pinned <2.20 since target VMs run Python 3.8, which ansible-core dropped support for starting in 2.20
sudo su - action-runner -c "pipx install 'ansible-core<2.20'"
sudo su - action-runner -c 'export PATH="$(cat /opt/runner-cache/.path):$PATH"; ansible-galaxy collection install ansible.windows azure.azcollection ansible.posix community.general --force'
sudo su - action-runner -c "/opt/runner-cache/.local/share/pipx/venvs/ansible-core/bin/python3 -m pip install -r /opt/runner-cache/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt"
# auth_source: cli in azure.azcollection requires azure-cli-core importable in the same venv (not the full azure-cli metapackage, which conflicts with the collection's pinned SDK deps)
sudo su - action-runner -c "pipx inject ansible-core azure-cli-core pywinrm jmespath pygithub setuptools"

# Set docker registry mirror 'https://cloud.google.com/artifact-registry/docs/pull-cached-dockerhub-images#cli'
printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
sudo service docker restart

./svc.sh install action-runner
# Last step, run it!
./svc.sh start
./svc.sh status
