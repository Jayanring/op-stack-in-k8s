#! /bin/bash

python -u deploy.py

while IFS="=" read -r key value; do
    if [[ ! -z "$key" && ! -z "$value" ]]; then
        export "$key=$value"
    fi
done < /env/.env
echo -e "\nETH_RPC_URL: $ETH_RPC_URL"
export DEPLOYMENT_CONTEXT=chain-cache

echo -e "\ndeploying rollup contracts..."

cd contracts-bedrock

forge script scripts/Deploy.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL && \

if [ $? -eq 0 ]; then
    echo "deploy rollup contracts success"
else
    echo "deploy rollup contracts failed"
    exit 1
fi

forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL

if [ $? -eq 0 ]; then
    echo "rollup sync success"
else
    echo "rollup sync contracts failed"
    exit 1
fi
sleep 3

echo $ETH_RPC_URL > ./ETH_RPC_URL

echo $L2_ChainID > ./L2_ChainID

echo $SEQUENCER_KEY > ./SEQUENCER_KEY

echo $BATCHER_KEY > ./BATCHER_KEY

echo $(cat ./contracts-bedrock/deployments/chain-cache/L1StandardBridgeProxy.json | jq -r .address) > ./L1StandardBridgeProxy

echo $(cat ./contracts-bedrock/deployments/chain-cache/L2OutputOracleProxy.json | jq -r .address) > ./L2OutputOracleProxy
