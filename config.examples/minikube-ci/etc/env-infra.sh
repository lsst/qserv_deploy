# Use '-MK-' for minikube
MASTER="-MK-"

# Use one '-MK-' per node for minikube
WORKERS="-MK- -MK-"

# Used for ssh access to Kubernetes master
ORCHESTRATOR="$HOSTNAME"

STORAGE_SIZE="3Ti"

# Enable Minikube
MINIKUBE=true
export MINIKUBE
