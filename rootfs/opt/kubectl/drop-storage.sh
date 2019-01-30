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

# Drops K8s Volumes and Claims for Master and Workers

# @author Fabrice Jammes, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

usage() {
    cat << EOD

    Usage: $(basename "$0") <volume_type>

    Available options:
      -h          this message

      Drop Qserv Volumes and Claims for volume type <volume_type>
      <volume_type> might be 'data' or 'tmp'
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

VOLUME_TYPE="$1"

DATA_ID=0

for host in $MASTER $WORKERS;
do
    kubectl delete pv "qserv-${VOLUME_TYPE}-pv-${DATA_ID}"
    kubectl delete pvc "qserv-${VOLUME_TYPE}-qserv-${DATA_ID}"
    DATA_ID=$((DATA_ID+1))
done
kubectl delete -f "${DIR}/yaml/qserv-storageclass.yaml"
