#!/bin/sh

# print chunk lists for all nodes

# @author Fabrice Jammes IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

DATA_DIR="/qserv/data/mysql/qservTest_case150_qserv"
RESULT_DIR="out_chunks"

mkdir -p "$RESULT_DIR"

TABLE="deepCoadd_forced_src"

echo "List chunks in $DATA_DIR on all nodes"
parallel --results "$RESULT_DIR" "kubectl exec {} -c mariadb -- sh -c 'find  $DATA_DIR -name \"$TABLE_*.frm\" | \
    grep -v \"1234567890.frm\" | \
    sed \"s;${DATA_DIR}/$TABLE_\([0-9][0-9]*\)\.frm$;\1;\"'" ::: $MASTER_POD $WORKER_PODS
