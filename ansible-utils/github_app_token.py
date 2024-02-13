#!/usr/bin/env python3
import os
from github import GithubIntegration, Auth

from argparse import ArgumentParser

def gen_token_from_github_app(org, app_id, private_key):
    integration = GithubIntegration(auth=Auth.AppAuth(app_id=app_id, private_key=private_key))
    # Get an installation access token
    installation_id = integration.get_org_installation(org)
    access_token = integration.get_access_token(installation_id.id).token
    print(access_token)

def process_args():
    parser = ArgumentParser()
    parser.add_argument('-o', '--org', type=str)
    parser.add_argument('-a', '--appid', type=str)
    parser.add_argument('-p', "--privatekey", type=str)
    return parser.parse_args()

if __name__ == '__main__' :
    args = process_args()    
    gen_token_from_github_app(org=args.org, app_id=args.appid, private_key=args.privatekey)