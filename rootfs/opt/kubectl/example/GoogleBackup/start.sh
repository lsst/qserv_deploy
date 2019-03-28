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

# Start backup

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env-infra.sh"
. "$QSERV_CFG_DIR/env.sh"

CONFIGMAP_DIR="${DIR}/configmap"
MANIFEST_DIR="${DIR}/manifest"

OUTDIR=$(mktemp -d --tmpdir="/tmp/qserv-deploy" --suffix="-backup-yaml")

usage() {
  cat << EOD

  Usage: $(basename "$0") [options]

  Available options:
    -h          this message
    -R          restore Qserv data

  Launch Qserv data backup procedure for GKE

EOD
}

# get the options
while getopts hR c ; do
    case $c in
        h) usage ; exit 0 ;;
        R) OPT_RESTORE='-R' ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

KUBECTL_CM="kubectl create configmap -o yaml --dry-run"
KUBECTL_SECRET="kubectl create secret generic -o yaml --dry-run"
KUBECTL_LABEL="kubectl label --local -f - app=qserv -o yaml"

# TODO crash script if KUBECTL_CM crash
$KUBECTL_CM --from-file="$CONFIGMAP_DIR" config-backup-start | \
    $KUBECTL_LABEL > ${OUTDIR}/config-backup-start.yaml

$KUBECTL_SECRET secret-backup \
        --from-file="/tmp/qserv-deploy/secret/neural-theory-215601-53bf50004612.json" | \
        $KUBECTL_LABEL > ${OUTDIR}/secret-backup.yaml

YAML_TPL="${MANIFEST_DIR}/statefulset-backup.tpl.yaml"

# # TODO add ini file instead of option
# cat << EOF > "$INI_FILE"
# [spec]
# gke: $INI_GKE
# storage_size: $STORAGE_SIZE
# sdk_image: $MARIADB_IMAGE
# restore: False
# EOF

tier="qserv"
YAML_FILE="${OUTDIR}/statefulset-${tier}-backup.yaml"
"$DIR"/yaml-builder.py -T "${tier}" -r ${WORKER_COUNT} -t "$YAML_TPL" -o "$YAML_FILE" $OPT_RESTORE

tier="czar"
YAML_FILE="${OUTDIR}/statefulset-${tier}-backup.yaml"
"$DIR"/yaml-builder.py -T "${tier}" -t "$YAML_TPL" -o "$YAML_FILE" $OPT_RESTORE

# TODO prefix all volumeClaimName with qserv-data
tier="repl-db"
YAML_FILE="${OUTDIR}/statefulset-${tier}-backup.yaml"
"$DIR"/yaml-builder.py -T "${tier}" -V "repl-data" -t "$YAML_TPL" -o "$YAML_FILE" $OPT_RESTORE

kubectl apply -f "${OUTDIR}"
