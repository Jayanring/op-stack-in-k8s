#! /usr/bin/python

import dotenv
import os
from web3 import Web3
import subprocess

dotenv.load_dotenv("./config/.env")


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
        .replace("_PROPOSER", os.getenv("PROPOSER"))
        .replace("_TIMESTAMP", timestamp)
        .replace("_BLOCKHASH", hash)
    )


new_config = update_deploy_config(config, hash, timestamp)
deploy_name = os.getenv("DEPLOYMENT_CONTEXT")

with open(f"contracts-bedrock/deploy-config/{deploy_name}.json", "w") as file:
    file.write(new_config)
print("\nupdate deploy config success")


try:
    os.mkdir(f"contracts-bedrock/deployments/{deploy_name}")
except:
    FileExistsError

url = os.getenv("ETH_RPC_URL")
key = os.getenv("PRIVATE_KEY")

print("\ndeploying rollup contracts...")
deploy = f"cd contracts-bedrock;forge script scripts/Deploy.s.sol:Deploy --private-key {key} --broadcast --rpc-url {url};forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key {key} --broadcast --rpc-url {url}"
result = subprocess.run(
    deploy, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
)
print("Deploy Contracts Stdout:")
print(result.stdout)
if result.returncode == 0:
    print("deploy rollup contracts success")
else:
    print("deploy rollup contracts failed")


print("\ngenerating L2 config...")
generate_config = f"./op-node genesis l2 \
    --deploy-config ./contracts-bedrock/deploy-config/{deploy_name}.json \
    --deployment-dir ./contracts-bedrock/deployments/{deploy_name}/ \
    --outfile.l2 ./config/genesis.json \
    --outfile.rollup ./config/rollup.json \
    --l1-rpc {url}"
result = subprocess.run(
    generate_config,
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
)
print("Generate Config Stdout:")
print(result.stdout)
if result.returncode == 0:
    print("generate L2 config success")
else:
    print("generate L2 config failed")

subprocess.run(
    f"echo $(cat deployments/{deploy_name}/L1StandardBridgeProxy.json | jq -r .address) > ./config/L1StandardBridgeProxy",
    shell=True,
    text=True,
)
subprocess.run(
    f"echo $(cat deployments/{deploy_name}/L2OutputOracleProxy.json | jq -r .address) > ./config/L2OutputOracleProxy",
    shell=True,
    text=True,
)
