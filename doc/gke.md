# Create a gke cluster

This might be useful for development purpose or ephemeral large scale tests.

## Pre-requisites

Apply [README](../README.md) pre-requisites, with 'gke-dev' directory.

## Create cluster

```shell
    # Launch qserv-deploy
    ./qserv-deploy.sh -C "$QSERV_CFG_DIR"
    
    # Authenticate
    /opt/gcp/init.sh

    # Edit cluster configuration
    vi /etc/qserv-deploy/env-infra.sh

    # Create cluster
    /opt/gcp/create-gke-cluster.sh
    /opt/gcp/setup-nodepools.sh
```

## Resize cluster

```shell
    # Downsize cluster, not to pay
    /opt/gcp/downsize-nodepools.sh

    # Upsize cluster to initial size
    /opt/gcp/upsize-nodepools.sh
```