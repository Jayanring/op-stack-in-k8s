# op-stack-one-click

1. 填写配置项
   cp op-deployer/.env.example op-deployer/config/.env
2. 部署合约得到配置文件
   docker run -it -v ./op-deployer/config/:/deploy/config/ --rm --network host --name deployer jayanring/op-deployer
3. 