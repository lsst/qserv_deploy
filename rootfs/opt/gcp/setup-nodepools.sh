#!/bin/sh

# Create czar and worker node pools for GKE cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$QSERV_CFG_DIR/env-infra.sh"

$DIR/create-nodepool.sh "pool-czar" "$MTYPE_CZAR" "$SIZE_CZAR"