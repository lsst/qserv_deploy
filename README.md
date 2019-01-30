# qserv_deploy on gke

Automated procedure to spawn Qserv on a Kubernetes cluster.

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

# Prequisites

* An up and running Kubernetes cluster.

* Create a cluster configuration directory:

```shell
   git clone https://github.com/lsst/qserv_deploy.git

   # Create a directory to store your cluster(s) configuration
   export QSERV_CFG_DIR="$HOME/.qserv/"
   mkdir -p $QSERV_CFG_DIR

   cp -r qserv_deploy/config.examples/gke-dev "$QSERV_CFG_DIR"
```
## Retrieve kubeconfig 

### For bare-metal cluster

On docker host, copy your kubeconfig file to "$QSERV_CFG_DIR/dot-kube"

### For gke cluster

Start the tool by running `./qserv-deploy.sh -C "$QSERV_CFG_DIR"`
Then get kubeconfig for your gke cluster, following example below:
```
gcloud auth login
. /etc/qserv-deploy/env-infra.sh
gcloud config set project "$PROJECT"
gcloud container clusters get-credentials "$CLUSTER" --zone us-central1-a --project "$PROJECT"
```

# Usage

## Install Qserv

If not already done, start the tool by running `./qserv-deploy.sh -C "$QSERV_CFG_DIR"`

In the container, all commands are prefixed with "qserv-"

Your working directory is $HOME with your cluster configuration mounted in "/etc/qserv_deploy"


# Commands list

* `qserv-start`: Start Qserv on the cluster (and create all pods)
* `qserv-status`: Show Qserv running status
* `qserv-stop`: Stop Qserv (and remove all pods)
* `/opt/kubectl/run-multinode-tests.sh`: Run integration tests

## Clean up storage

```
# WARN: this will delete all persistent volumes and volumes claims in your project
kubectl delete pvc --all
kubectl delete pv --all
```
