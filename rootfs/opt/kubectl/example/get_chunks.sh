#!/bin/sh

set -x
# set -e

# Print chunk lists for all nodes

# @author Fabrice Jammes IN2P3

set -e

DATA_DIR="/qserv/data/mysql/qservTest_case175_qserv"
TABLE="deepCoadd_forced_src"

DIR=$(cd "$(dirname "$0")"; pwd -P)

PODS=$(kubectl get pods -l 'app=qserv,tier in (worker)' -o go-template="{{range .items}}{{.metadata.name}} {{end}}")

RESULT_DIR="$DIR/out_chunks"

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

echo "List chunks in $DATA_DIR on all nodes"
parallel --result "$RESULT_DIR" "kubectl exec {} -c mariadb -- sh -c 'echo \$(hostname) && find  $DATA_DIR -name \"${TABLE}_*.frm\" | \
    grep -v \"1234567890.frm\" | \
    sed \"s;${DATA_DIR}/${TABLE}_\([0-9][0-9]*\)\.frm$;\1;\"'" ::: $PODS
