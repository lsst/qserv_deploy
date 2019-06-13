# Create a kind cluster

This might be useful for development purpose.

## Pre-requisites

Apply [README](../README.md) pre-requisites, with 'kind' directory.

## Create cluster

```shell
    cd qserv_deploy

    # Launch k8s
    ./kind/k8s-create.sh

    # Launch Qserv
    # NOTE: read carefully this script to understand how to do it manually
    ./kind/launch.sh
```
