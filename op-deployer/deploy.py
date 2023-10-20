#! /usr/bin/python

import dotenv
import os
from web3 import Web3
import subprocess

dotenv.load_dotenv("/env/.env")


def deploy_config_template():
    with open(f"contracts-bedrock/deploy-config/template", "r") as file:
        return file.read()


config = deploy_config_template()


def get_L1_latest_block():
    url = os.getenv("ETH_RPC_URL")
    from web3.middleware import geth_poa_middleware

    web3 = Web3(Web3.HTTPProvider(url))
    web3.middleware_onion.inject(geth_poa_middleware, layer=0)
    latest_block = web3.eth.get_block("latest")
    hash = latest_block["hash"].hex()
    number = latest_block["number"].__str__()
    timestamp = latest_block["timestamp"].__str__()
    return hash, number, timestamp


hash, number, timestamp = get_L1_latest_block()
print(f"\nget start block: height: {number}, timestamp: {timestamp}, hash: {hash}")


def update_deploy_config(config: str, hash, timestamp):
    return (
        config.replace("_L1_BlockTime", os.getenv("L1_BlockTime"))
        .replace("_L1_ChainID", os.getenv("L1_ChainID"))
        .replace("_L2_BlockTime", os.getenv("L2_BlockTime"))
        .replace("_L2_ChainID", os.getenv("L2_ChainID"))
        .replace("_ADMIN", os.getenv("ADMIN"))
        .replace("_SEQUENCER", os.getenv("SEQUENCER"))
        .replace("_BATCHER", os.getenv("BATCHER"))
        .replace("_PROPOSER", "0x1879C8B68c50A4D4eeC9852325d32B60B43f3FbD")
        .replace("_TIMESTAMP", timestamp)
        .replace("_BLOCKHASH", hash)
    )


new_config = update_deploy_config(config, hash, timestamp)

os.environ['DEPLOYMENT_CONTEXT'] = 'chain-cache'
deploy_name = os.getenv("DEPLOYMENT_CONTEXT")
print(f"deploy_name: {deploy_name}")

with open(f"contracts-bedrock/deploy-config/{deploy_name}.json", "w") as file:
    file.write(new_config)
print("\nupdate deploy config success")


try:
    os.mkdir(f"contracts-bedrock/deployments/{deploy_name}")
except:
    FileExistsError
