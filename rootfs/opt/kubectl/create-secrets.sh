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

# Create Qserv secrets if they do not exists yet, else does nothing

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

SECRET_DIR="/tmp/qserv-deploy/secret"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options] <output_directory>

  Available options:
    -h          this message

  Produce yaml files for Qserv secrets in <output_directory>,
  if they do not exists, else does nothing.
  Output directory must exist and be writable.
  Secret input must be available in ${SECRET_DIR}.

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

KUBECTL_SECRET="kubectl create secret generic -o yaml --dry-run"
KUBECTL_LABEL="kubectl label --local -f - app=qserv -o yaml"

if  kubectl get secret -l app=qserv --no-headers  > /dev/null 2>&1
then
    echo "Create kubernetes secrets for Qserv"
    $KUBECTL_SECRET secret-wmgr \
        --from-file="$SECRET_DIR/wmgr.secret" | \
        $KUBECTL_LABEL > $outdir/secret-wmgr.yaml

    $KUBECTL_SECRET secret-mariadb \
        --from-file="$SECRET_DIR/mariadb.secret.sh" | \
        $KUBECTL_LABEL > $outdir/secret-mariadb.yaml
else
    echo "WARN: use existing secrets"
fi
