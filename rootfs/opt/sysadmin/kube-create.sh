#!/bin/bash

# Create Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

#CNI_PLUGIN="calico"
#CNI_PLUGIN="flannel"
CNI_PLUGIN="weave"

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env-sysadmin.sh"

echo "Create Kubernetes cluster"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- systemctl start kubelet"
TOKEN=$(ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm token generate")

# Enable use of kubectl through ssh tunnel
SSH_TUNNEL_OPT="--apiserver-cert-extra-sans=localhost"

case "$CNI_PLUGIN" in
        calico)
            CNI_OPT="--pod-network-cidr=192.168.0.0/16"
            ;;

        flannel)
            CNI_OPT="--pod-network-cidr=10.244.0.0/16"
            ;;

esac

ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm init $SSH_TUNNEL_OPT \
    $CNI_OPT --token '$TOKEN'"

"$DIR"/export-kubeconfig.sh

"$DIR"/../kubectl/install-cni.sh "$CNI_PLUGIN"

HASH=$(ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo openssl x509 -pubkey -in \
    /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null \
	| openssl dgst -sha256 -hex | sed 's/^.* //'")

JOIN_CMD="kubeadm join --token '$TOKEN' \
    --discovery-token-ca-cert-hash 'sha256:$HASH' \
    $ORCHESTRATOR:6443"

# Join Kubernetes nodes
parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- systemctl start kubelet && \
    sudo -- $JOIN_CMD"
