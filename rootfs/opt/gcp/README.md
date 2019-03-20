# Create a GKE cluster for Qserv

```shell

# Edit file to set up cluster attribute
vi /etc/qserv-deploy/env-infra.sh

# Create GKE cluster
./create-gke-cluster.sh

# Create node pool for czar and worker
./setup-nodepools.sh

# Retrieve kubeconfig
/opt/gcp/get_kubeconfig.sh
```
