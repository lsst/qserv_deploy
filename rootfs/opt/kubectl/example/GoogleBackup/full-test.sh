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

# Test for example backup procedure for GKE,
# Need to be launch inside qserv-deploy container
# Some interactive operations need to be performed after
# backup and restore procedure

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env-infra.sh"
. "$QSERV_CFG_DIR/env.sh"

/opt/gcp/create-gke-cluster.sh
/opt/gcp/setup-nodepools.sh

qserv-start
/opt/kubectl/run-multinode-tests.sh
qserv-stop

$DIR/start.sh
# WARN Need to be run interactively
kubectl delete statefulset -l app=qserv
kubectl delete pvc -l app=qserv

$DIR/start.sh -R
# WARN Need to be run interactively
kubectl delete statefulset -l app=qserv
qserv-start

kubectl exec czar-0 -c proxy -- su qserv -l -c ". /qserv/stack/loadLSST.bash && \
    setup qserv_distrib -t qserv-dev && \
    echo \"$CSS_INFO\" | qserv-admin.py -c mysql://qsmaster@127.0.0.1:3306/qservCssData && \
    qserv-check-integration.py"