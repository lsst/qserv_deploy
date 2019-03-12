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

# Update Qserv configmaps 

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CONFIGMAP_DIR="${DIR}/configmap"
CZAR="czar-0"
REPL_CTL="repl-ctl"
REPL_DB="repl-db-0"
QSERV_DOMAIN="qserv"
CZAR_DN="${CZAR}.${QSERV_DOMAIN}"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options] <output_directory>

  Available options:
    -h          this message

  Produce yaml files for Qserv configmaps in <output_directory>.
  Output directory must exist and be writable.

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

if [ $# -ne 1 ] ; then
    usage
    exit 2
fi

outdir=$1

# strip trailing slash
outdir=$(echo $outdir | sed 's%\(.*[^/]\)/*%\1%')


echo "Create or update kubernetes configmaps for Qserv"

KUBECTL_CM="kubectl create configmap -o yaml --dry-run"
KUBECTL_SECRET="kubectl create secret generic -o yaml --dry-run"
KUBECTL_LABEL="kubectl label --local -f - app=qserv -o yaml"

$KUBECTL_CM config-domainnames --from-literal=CZAR="$CZAR" \
    --from-literal=CZAR_DN="$CZAR_DN" \
    --from-literal=QSERV_DOMAIN="$QSERV_DOMAIN" \
    --from-literal=REPL_CTL="$REPL_CTL" \
    --from-literal=REPL_DB="$REPL_DB" | $KUBECTL_LABEL > $outdir/config-domainnames.yaml

$KUBECTL_CM --from-file="$CONFIGMAP_DIR/dot-lsst" config-dot-lsst | $KUBECTL_LABEL > $outdir/config-dot-lsst.yaml

$KUBECTL_CM --from-file="$CONFIGMAP_DIR/init/mariadb-configure.sh" config-mariadb-configure | \
    $KUBECTL_LABEL > $outdir/config-mariadb-configure.yaml

DATABASES="czar repl worker"
for db in $DATABASES
do
    $KUBECTL_CM --from-file="$CONFIGMAP_DIR/init/sql/$db" "config-sql-$db" | \
        $KUBECTL_LABEL > $outdir/config-sql-$db.yaml
done

SERVICES="mariadb proxy repl-ctl repl-db repl-wrk wmgr xrootd"
for service in $SERVICES
do
    $KUBECTL_CM --from-file="$CONFIGMAP_DIR/$service/etc" config-${service}-etc | \
        $KUBECTL_LABEL > $outdir/config-${service}-etc.yaml
    $KUBECTL_CM --from-file="$CONFIGMAP_DIR/$service/start" config-${service}-start | \
        $KUBECTL_LABEL > $outdir/config-${service}-start.yaml
done

echo "Create kubernetes secrets for Qserv"
$KUBECTL_SECRET secret-wmgr \
        --from-file="$CONFIGMAP_DIR/wmgr/wmgr.secret" | \
        $KUBECTL_LABEL > $outdir/secret-wmgr.yaml

