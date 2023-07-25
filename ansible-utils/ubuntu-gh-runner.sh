#!/bin/bash

GITHUB_ORG_NAME=$1
GITHUB_APP_ID=$2
GITHUB_APP_PRIVATE_KEY_ENCODED=$3


GITHUB_APP_PRIVATE_KEY=$(echo $GITHUB_APP_PRIVATE_KEY_ENCODED | base64 --decode) 
# Generate the github runner registration token 
ACCESS_TOKEN=$(python3 github_app_token.py -o $GITHUB_ORG_NAME -a $GITHUB_APP_ID -p "$GITHUB_APP_PRIVATE_KEY")
echo ACCESS_TOKEN=$ACCESS_TOKEN
# Generate the GitHub runner token
response=$(curl -X POST \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/orgs/$GITHUB_ORG_NAME/actions/runners/registration-token")
echo "response=$response"
# Extract the token from the response
TOKEN=$(echo "$response" | jq -r '.token')
echo "RUNNER_TOKEN=$TOKEN"

# Install Github runner agent
mkdir /usr/local/bin/actions-runner
cd /usr/local/bin/actions-runner

chown action-runner /usr/local/bin/actions-runner --recursive
chgrp action-runner /usr/local/bin/actions-runner --recursive
useradd -d /usr/local/bin/actions-runner action-runner
usermod -aG sudo action-runner

echo "[---DEBUG1---]"
# Download the latest runner package
curl -o actions-runner-linux-x64-2.306.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.306.0/actions-runner-linux-x64-2.306.0.tar.gz
echo "[---DEBUG2---]"
# Optional: Validate the hash
echo "b0a090336f0d0a439dac7505475a1fb822f61bbb36420c7b3b3fe6b1bdc4dbaa  actions-runner-linux-x64-2.306.0.tar.gz" | shasum -a 256 -c
echo "[---DEBUG3---]"
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.306.0.tar.gz
echo "[---DEBUG4---]"
# Create the runner and start the configuration experience
export RUNNER_ALLOW_RUNASROOT=1
./config.sh --url https://github.com/tecgovtnz --token $TOKEN --runasservice --name $(hostname) --work ~/_work --runnergroup Default --labels Linux
echo "[---DEBUG5---]"
#install as a service account
./svc.sh install action-runner
echo "[---DEBUG6---]"
# Last step, run it!
./svc.sh start
./svc.sh status
