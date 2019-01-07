#!/bin/sh

# Creates K8s Volumes and Claims for Master and Workers

# @author Benjamin Roziere, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

usage() {
    cat << EOD

    Usage: $(basename "$0") <hostPath> <dataName>

    Available options:
      -h          this message

      Create Qserv Volumes and Claims for Path <hostPath>

EOD
}

while getopts hp: c ; do
    case $c in
        h) usage; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 2  ] ; then
    usage
    exit 2
fi

if [ "$GKE" = true ]; then
    exit
elif [ "$MINIKUBE" = true ]; then
    exit
fi

DATA_PATH="$1"
DATA_NAME="$2"

STORAGE_OUTPUT_DIR="$QSERV_CFG_DIR"/storage

mkdir -p $STORAGE_OUTPUT_DIR


kubectl apply -f "${DIR}/yaml/qserv-storageclass.yaml"
echo "Creating persistent volume and claim for Qserv czar"
DATA_ID="czar-0"
if [ "$MINIKUBE" = true ]; then
    OPT_HOST=
else
    OPT_HOST="-H $MASTER"
fi
"$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pv-${DATA_ID}.yaml"
kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pvc-${DATA_ID}.yaml"

echo "Creating persistent volumes and claims for Qserv nodes"
COUNT=0
for host in $WORKERS;
do
    if [ "$MINIKUBE" = true ]; then
        OPT_HOST=
    else
        OPT_HOST="-H $host"
    fi
    DATA_ID="qserv-${COUNT}"
    "$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pv-${DATA_ID}.yaml"
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pvc-${DATA_ID}.yaml"
    COUNT=$((COUNT+1))
done
