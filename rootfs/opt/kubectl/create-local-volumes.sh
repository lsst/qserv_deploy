#!/bin/sh

# LSST Data Management System
# Copyright 2014 LSST Corporation.
# 
# This product includes software developed by the
# LSST Project (http://www.lsst.org/).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the LSST License Statement and 
# the GNU General Public License along with this program.  If not, 
# see <http://www.lsstcorp.org/LegalNotices/>.

# Creates K8s Volumes and Claims for Master and Workers

# @author Benjamin Roziere, IN2P3
# @author Fabrice Jammes, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env-infra.sh"
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

YAML_OUT_DIR=$(mktemp -d --tmpdir="/tmp/qserv-deploy" --suffix="-storage-yaml")

kubectl apply -f "${DIR}/yaml/qserv-storageclass.yaml"

echo "Creating persistent volume and claim for Qserv czar"
DATA_ID="czar-0"
OPT_HOST="-H $MASTER"
DATA_NAME="qserv-data"
DATA_PATH="$STORAGE_PATH/data"
"$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$YAML_OUT_DIR"

echo "Creating persistent volumes and claims for Qserv pods"
COUNT=0
for host in $WORKERS;
do
    OPT_HOST="-H $host"
    DATA_ID="qserv-${COUNT}"
    "$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$YAML_OUT_DIR"
    COUNT=$((COUNT+1))
done

echo "Creating persistent volumes and claims for Replication Database pod"
OPT_HOST="-H $MASTER"
DATA_NAME="repl-data"
DATA_ID="repl-db-0"
DATA_PATH="$STORAGE_PATH/repl-data"
"$DIR"/storage-builder.py -p "$DATA_PATH" -n "$DATA_NAME" $OPT_HOST -d "$DATA_ID" -o "$YAML_OUT_DIR"

kubectl apply -f "${YAML_OUT_DIR}"
