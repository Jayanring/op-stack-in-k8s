# op-stack-in-k8s

1. 填写配置项，要保证Admin账户余额能够支付gas

   `vim ./cm_env_template.yaml`

2. 复制配置文件

   `cp ./cm_env_template.yaml ./yamls/l2-init/cm_env.yaml`

3. 初始化L2，这会执行一个Job，需耗时5min左右

   `kubectl apply -f yamls/l2-init/ -nns`

4. 部署sequencer

   `kubectl apply -f yamls/l2-sequencer/ -nns`

5. 获取sequencer op-node p2p 信息

   `kubectl exec -it l2-sequencer-0 -c op-node -nns -- cat PeerID`

   输出如：`16Uiu2HAkwiUpadtu12nrKyrAi73rCBGdjXEYTwCDHJzn9E7QAjab`，用它替换`./yamls/l2-verifier/sts_verifier.yaml`中的`[OP_NODE_P2P]`

6. 获取sequencer op-geth p2p 信息

   `kubectl exec -it l2-sequencer-0 -c op-geth -nns -- geth --exec "admin.nodeInfo.enode" attach datadir/geth.ipc`

   输出如`"enode://d41da330fafc325c2173815fa58c5ce5e38868b4b4c610264a10aeb90a1f32cd28c55fb6f272966e8edbea7b43ddbe2f380855e6da9f4c2ccf96c55775e9fae3@127.0.0.1:30303"`

   只需要`d41da330fafc325c2173815fa58c5ce5e38868b4b4c610264a10aeb90a1f32cd28c55fb6f272966e8edbea7b43ddbe2f380855e6da9f4c2ccf96c55775e9fae3`

   用它替换`./yamls/l2-verifier/sts_verifier.yaml`中的`[OP_GETH_P2P]`

7. 部署verifier，查看rpc，查看跨链桥地址

   `kubectl apply -f yamls/l2-verifier/ -nns`

   rpc: `kubectl get svc -nns | grep "l2-verifier-rpc" | awk '{print $4}'`

   L1跨链桥地址：`kubectl exec -it l2-verifier-0 -c op-node -nns -- cat config/L1StandardBridgeProxy`

8. 部署区块链浏览器

   `kubectl apply -f yamls/l2-explorer/ -nns`

   ip: `kubectl get svc -nns | grep "l2-verifier-explorer" | awk '{print $4}'`
