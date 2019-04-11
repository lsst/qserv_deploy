#!/bin/sh

# Setup ulimit and launch xrootd startup script

# @author  Fabrice Jammes, IN2P3/SLAC

set -e

# TODO put in CM
XROOTD_MANAGER="xrootd-0"
export XROOTD_DN="${XROOTD_MANAGER}.${QSERV_DOMAIN}"

if [ "$HOSTNAME" = "$XROOTD_MANAGER" ]; then
    INSTANCE_NAME='master'
else
    INSTANCE_NAME='worker'
fi
export INSTANCE_NAME

su qserv -c "sh /config-start/cmsd.sh"
