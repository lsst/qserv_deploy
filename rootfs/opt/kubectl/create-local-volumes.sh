#!/bin/sh

# Creates K8s Volumes and Claims for Master and Workers

# @author Benjamin Roziere, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

usage() {
    cat << EOD

    Usage: $(basename "$0") <hostPath>

    Available options:
      -h          this message

      Create Qserv Volumes and Claims for toplevel Path <hostPath>

EOD
}

while getopts hp: c ; do
    case $c in
        h) usage; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 1  ] ; then
    usage
    exit 2
fi

if [ "$GKE" = true ]; then
    exit
elif [ "$MINIKUBE" = true ]; then
    exit
fi

STORAGE_PATH="$1"

STORAGE_OUTPUT_DIR="$QSERV_CFG_DIR"/storage

mkdir -p $STORAGE_OUTPUT_DIR


kubectl apply -f "${DIR}/yaml/qserv-storageclass.yaml"

echo "Creating persistent volume and claim for Qserv czar"
DATA_ID="czar-0"
OPT_HOST="-H $MASTER"
DATA_NAME="qserv-data"
DATA_PATH="$STORAGE_PATH/data"
"$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pv-${DATA_ID}.yaml"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pvc-${DATA_ID}.yaml"

echo "Creating persistent volumes and claims for Qserv pods"
COUNT=0
for host in $WORKERS;
do
    OPT_HOST="-H $host"
    DATA_ID="qserv-${COUNT}"
    "$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pv-${DATA_ID}.yaml"
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pvc-${DATA_ID}.yaml"
    COUNT=$((COUNT+1))
done

echo "Creating persistent volumes and claims for Replication Database pod"
OPT_HOST="-H $MASTER"
DATA_NAME="repl-data"
DATA_ID="repl-db-0"
DATA_PATH="$STORAGE_PATH/repl-data"
"$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pv-${DATA_ID}.yaml"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/${DATA_NAME}-pvc-${DATA_ID}.yaml"
