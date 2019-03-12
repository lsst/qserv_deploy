#!/bin/sh

# Create node pool for GKE cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

. "$QSERV_CFG_DIR/env-infra.sh"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options] <pool-name> <machine-type> <size>

  Available options:
    -h          this message

  Create node pool for GKE cluster

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 3 ] ; then
    usage
    exit 2
fi

POOL_NAME=$1
MTYPE=$2
SIZE=$3

gcloud beta container --project "$PROJECT" node-pools create "$POOL_NAME" \
    --cluster "$CLUSTER" --zone "$ZONE" --node-version "$GKE_CLUSTER_VERSION" \
    --machine-type "$MTYPE" --image-type "COS" \
    --disk-type "pd-standard" --disk-size "100" \
    $PREEMPTIBLE_OPT \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --num-nodes "$SIZE" --no-enable-autoupgrade --enable-autorepair
