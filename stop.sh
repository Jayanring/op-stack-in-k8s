#! /bin/bash

# 设置环境变量
source ./env.sh

kubectl delete -f ./yamls/l2-explorer/sts_explorer.yaml -n $NAME_SPACE
kubectl delete -f ./yamls/l2-sequencer/sts_sequencer.yaml -n $NAME_SPACE
kubectl delete -f ./yamls/l2-verifier/sts_verifier.yaml -n $NAME_SPACE
