#!/bin/sh

set -e
set -x

abs_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

DIR=$(cd "$(dirname "$0")"; pwd -P)
BASE=$(abs_path "$DIR/..")

QSERV_CFG_DIR="$HOME/.qserv/minikube"
rm -rf "$QSERV_CFG_DIR"

"$BASE"/init-cfg.sh "$BASE"/config.examples/minikube-ci "$BASE"/secret.examples "$QSERV_CFG_DIR"
cp "$HOME"/.kube/config "$QSERV_CFG_DIR"/dot-kube/config


"$BASE"/qserv-deploy.sh -M -C "$QSERV_CFG_DIR" -d /opt/bin/qserv-start

echo "Qserv pods are up:"
kubectl get pods --selector="app=qserv"

# TODO Add strong check for Qserv startup
sleep 10

"$BASE"/qserv-deploy.sh -M -C "$QSERV_CFG_DIR" -d /opt/kubectl/run-multinode-tests.sh
