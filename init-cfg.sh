#!/bin/sh

# Initialize the Qserv deploy container configuration

# @author Fabrice JAMMES <fabrice.jammes@in2p3.fr>

set -e
# set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` <source-cfg-dir> <source-secret-dir> <destination-dir>

   Initialize the Qserv deploy configuration from example directories.

   User can then tune its configuration by editing <destination-dir> files:
   - Configuration files are in <destination-dir>/etc
   - Secrets input are stored inside <destination-dir>/tmp/secret and will be moved
     inside k8s secrets at first Qserv startup.

EOD
}

if [ $# -ne 3 ] ; then
    usage
    exit 2
fi

SRC_CFG_DIR="$1"
SRC_SECRET_DIR="$2"
QSERV_CFG_DIR="$3"

if [ ! -d "$SRC_CFG_DIR" ]; then
    >&2 echo "ERROR: Non-existing directory for <source-cfg-dir> parameter: \"$SRC_CFG_DIR\""
    usage
    exit 1
elif [ ! -d "$SRC_SECRET_DIR" ]; then
    >&2 echo "ERROR: Non-existing directory for <source-secret-dir> parameter: \"$SRC_SECRET_DIR\""
    usage
    exit 1
elif [ -d "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Existing directory for <destination-dir> parameter: \"$QSERV_CFG_DIR\", remove or rename it"
    usage
    exit 1
fi

parentdir="$(dirname "$QSERV_CFG_DIR")"
mkdir -p "$parentdir"

# Copy example configuration
cp -r --dereference "$SRC_CFG_DIR" "$QSERV_CFG_DIR"

# Copy example secrets
mkdir "${QSERV_CFG_DIR}/tmp"
cp -r --dereference "$SRC_SECRET_DIR" "${QSERV_CFG_DIR}/tmp/secret"

mkdir "$QSERV_CFG_DIR/dot-kube"

echo "Succeed in creating configuration inside ${QSERV_CFG_DIR}"
