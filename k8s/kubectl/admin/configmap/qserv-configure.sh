#!/bin/bash

# LSST Data Management System
# Copyright 2014-2015 LSST Corporation.
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


# Configure Qserv on current node

# @author  Fabrice Jammes, IN2P3/SLAC

set -e

usage() {
  cat << EOD

Usage: $(basename "$0") [options]

  Available options:
    -h          this message

  Configure a Qserv worker/master image, at pod startup

  Environnement variable:
  - NODE_TYPE can be set to 'master', default to worker
EOD
}
NODE_TYPE=${NODE_TYPE:-worker}


# get the options
while getopts hm c ; do
    case $c in
            h) usage ; exit 0 ;;
            \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

QSERV_DATA_DIR=/qserv/data
QSERV_MASTER="master.qserv"
QSERV_RUN_DIR=/qserv/run
QSERV_CUSTOM_DIR=/qserv/custom

. /qserv/stack/loadLSST.bash
setup qserv_distrib -t qserv-dev

# May not be empty if current script has previously crashed
rm -rf "$QSERV_RUN_DIR/*"

echo "Configure Qserv $NODE_TYPE"
qserv-configure.py --init --force \
                   --qserv-run-dir "$QSERV_RUN_DIR" \
                   --qserv-data-dir "$QSERV_DATA_DIR"

# Customize meta configuration file
cp "$QSERV_RUN_DIR/qserv-meta.conf" /tmp/qserv-meta.conf.orig
awk \
-v NODE_TYPE_KV="node_type = $NODE_TYPE" \
-v MASTER_KV="master = $QSERV_MASTER" \
'{gsub(/node_type = mono/, NODE_TYPE_KV);
  gsub(/master = 127.0.0.1/, MASTER_KV);
  print}' /tmp/qserv-meta.conf.orig > "$QSERV_RUN_DIR/qserv-meta.conf"

echo "Configure Qserv $NODE_TYPE (master hostname: $QSERV_MASTER)"
qserv-configure.py --disable-db-init \
                   --qserv-run-dir "$QSERV_RUN_DIR" \
                   --force

mkdir "$QSERV_CUSTOM_DIR"
