#! /bin/bash

# 设置环境变量
source ./env.sh

output=$(kubectl get pvc l2-config-pvc -n $NAME_SPACE -o name)
if [ -z "$output" ]; then
    echo "l2-config-pvc not exist, start initiating"

    # 更新配置
    echo "deploy config: DOCKER_REGISTRY: $DOCKER_REGISTRY, DOCKER_REPO: $DOCKER_REPO, SC: $SC, NAME_SPACE: $NAME_SPACE"
    python ./update_config.py

    echo "check config in cm_env_template.yaml is correct, if not please interrupt this process"
    cp ./cm_env_template.yaml ./yamls/l2-init/cm_env.yaml

    # 初始化
    echo "deploy contract and generate rollup config"
    kubectl apply -f yamls/l2-init/ -n$NAME_SPACE >/dev/null

    # 等待Job完成
    echo "wait for completion..."
    kubectl wait --for=condition=complete --timeout=3600s job/l2-initer -n $NAME_SPACE
    echo "deploy success"

    # 清理
    kubectl delete -f ./yamls/l2-init/job_init.yaml -n $NAME_SPACE >/dev/null
    kubectl delete -f ./yamls/l2-init/cm_env.yaml -n $NAME_SPACE >/dev/null
else
    echo "l2-config-pvc exist, skip initiating"
fi

# 检查配置是否存在
echo -e "\ncheck rollup config"
output=$(kubectl get pod l2-test -n $NAME_SPACE -o name)
if [ -z "$output" ]; then
    echo "l2-test not exist, create"
    kubectl apply -f yamls/test.yaml -n$NAME_SPACE >/dev/null
    kubectl wait --for=condition=Ready --timeout=3600s pod/l2-test -n $NAME_SPACE
else
    echo "l2-test exist"
fi

CMD="if [ -s /config/L1StandardBridgeProxy -a -s /config/jwt.txt ]; then echo 'YES'; else echo 'NO'; fi"

OUTPUT=$(kubectl exec l2-test -c busybox -n $NAME_SPACE -- /bin/sh -c "$CMD")

if [ "$OUTPUT" != "YES" ]; then
    echo "missing config, check deploy process"
    exit 1
fi
echo "check rollup config success"

# 启动sequencer
echo -e "\nstart sequencer"
output=$(kubectl get pod l2-sequencer-0 -n $NAME_SPACE -o name)
if [ -z "$output" ]; then
    echo "sequencer not exist, create"
    kubectl apply -f yamls/l2-sequencer/ -n $NAME_SPACE >/dev/null
    kubectl wait --for=condition=Ready --timeout=3600s pod/l2-sequencer-0 -n $NAME_SPACE
else
    echo "sequencer exist"
fi

# 读取p2p信息并写入config中
sleep 3

while true; do
    kubectl exec l2-sequencer-0 -c op-geth -n $NAME_SPACE -- geth --exec "admin.nodeInfo.enode" attach datadir/geth.ipc >/dev/null
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "\nread sequencer geth p2p info"
        break
    else
        echo -e "\nread sequencer geth p2p info failed, retrying"
        sleep 1
    fi
done
output=$(kubectl exec l2-sequencer-0 -c op-geth -n $NAME_SPACE -- geth --exec "admin.nodeInfo.enode" attach datadir/geth.ipc)
output=$(echo $output | awk -F'[@:]' '{sub(/\/\//, "", $2); print $2}')
echo "OP_GETH_P2P: $output"
kubectl exec l2-test -c busybox -n $NAME_SPACE -- /bin/sh -c "echo $output > /config/OP_GETH_P2P"

while true; do
    kubectl exec l2-sequencer-0 -c op-node -n $NAME_SPACE -- ls PeerID >/dev/null
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        echo -e "\nread sequencer node p2p info"
        break
    else
        echo -e "\nread sequencer node p2p info failed, retrying"
        sleep 1
    fi
done
output=$(kubectl exec l2-sequencer-0 -c op-node -n $NAME_SPACE -- cat PeerID)
echo "OP_NODE_P2P: $output"
kubectl exec l2-test -c busybox -n $NAME_SPACE -- /bin/sh -c "echo $output > /config/OP_NODE_P2P"

# 启动verifier
echo -e "\nstart verifier"
output=$(kubectl get pod l2-verifier-0 -n $NAME_SPACE -o name)
if [ -z "$output" ]; then
    echo "verifier not exist, create"
    kubectl apply -f yamls/l2-verifier/ -n $NAME_SPACE >/dev/null
    kubectl wait --for=condition=Ready --timeout=3600s pod/l2-verifier-0 -n $NAME_SPACE
else
    echo "verifier exist"
fi

# 启动explorer
echo -e "\nstart explorer"
output=$(kubectl get pod l2-verifier-explorer-0 -n $NAME_SPACE -o name)
if [ -z "$output" ]; then
    echo "explorer not exist, create"
    kubectl apply -f yamls/l2-explorer/ -n $NAME_SPACE >/dev/null
    kubectl wait --for=condition=Ready --timeout=3600s pod/l2-verifier-explorer-0 -n $NAME_SPACE
else
    echo "explorer exist"
fi

# 打印服务信息
echo -e "\nRollup Info:"
echo Verifier RPC: $(kubectl get svc -n $NAME_SPACE | grep "l2-verifier-rpc" | awk '{print $4}'):8545
echo Explorer IP: $(kubectl get svc -n $NAME_SPACE | grep "l2-verifier-explorer" | awk '{print $4}'):4000
echo L1StandardBridgeProxy: $(kubectl exec l2-test -c busybox -n $NAME_SPACE -- cat config/L1StandardBridgeProxy)

kubectl delete -f yamls/test.yaml -n$NAME_SPACE >/dev/null

echo -e "\ncomplete!!!"
