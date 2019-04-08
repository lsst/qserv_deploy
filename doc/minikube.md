# Create a minikube cluster

This might be useful for development purpose.

## Pre-requisites

Apply [README](../README.md) pre-requisites, with 'minikube' directory.

## Create cluster

```shell
    cd qserv_deploy

    # Launch minikube
    # WARN: this procedure is fine for continous integration but might cause security
    # issues on a workstation
    ./minikube/minikube-create.sh

    # Launch Qserv
    # NOTE: read carefully this script to understand how to do it manually
    ./minikube/launch.sh
```