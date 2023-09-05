# op-stack-in-k8s

## start

1. Open the `env.sh` and `cm_env_template.yaml` file.

2. Fill in the required fields.

3. Save the changes.

4. `./apply.sh`

## stop

`./stop.sh`

* This will not delete `pvc` , `svc` and `configMap`

## clean

`./clean.sh`

* This will not delete `svc` and `configMap`