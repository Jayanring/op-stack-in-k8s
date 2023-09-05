#! /bin/bash

# 设置环境变量
source ./env.sh

kubectl delete -f ./yamls/l2-explorer/sts_explorer.yaml -n $NAME_SPACE
kubectl delete -f ./yamls/l2-sequencer/sts_sequencer.yaml -n $NAME_SPACE
kubectl delete -f ./yamls/l2-verifier/sts_verifier.yaml -n $NAME_SPACE
kubectl delete -f ./yamls/l2-init/ -n$NAME_SPACE
kubectl delete -f ./yamls/test.yaml -n$NAME_SPACE

kubectl delete pvc l2-config-pvc -n $NAME_SPACE
kubectl delete pvc datadir-sequencer-l2-sequencer-0 -n $NAME_SPACE
kubectl delete pvc datadir-verifier-l2-verifier-0 -n $NAME_SPACE
kubectl delete pvc datadir-verifier-explorer-l2-verifier-explorer-0 -n $NAME_SPACE