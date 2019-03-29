# qserv-deploy usage

Automated procedure to spawn Qserv on a Kubernetes cluster.

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

## Pre-requisites

* Docker must be installed and user must have access to docker daemon.

* Create a cluster configuration directory:

```shell
   git clone https://github.com/lsst/qserv_deploy.git

   # Create a directory to store your cluster(s) configuration
   mkdir -p "$HOME/.qserv/"

   # Use an example configuration, here the gke one
   cp -r qserv_deploy/config.examples/gke-dev "$HOME/.qserv/"

   # Optional
   QSERV_CFG_DIR="$HOME/.qserv/my-gke-cluster"
```

## Create a Kubernetes cluster (optional)

An existing up and running Kubernetes cluster might be used, or it is also possible to create one:
- on Google Kubernetes Engine: [GKE documentation](./doc/gke.md)
- on Minikube: [Minikube documentation](./doc/minikube.md)

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

## Start qserv-deploy

If not already done, start the tool by running `./qserv-deploy.sh -C "$QSERV_CFG_DIR"`

In the container, your working directory is $HOME with your cluster configuration mounted in "/etc/qserv_deploy"

## Commands list

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

## Cheat sheet

Additional `kubectl` commands for Qserv are available in this [cheat sheet](./doc/cheatsheet.md)