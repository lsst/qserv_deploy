#!/bin/sh

# Setup ulimit and launch xrootd startup script

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

export XROOTD_DN="${XROOTD_MANAGER}.${QSERV_DOMAIN}"

# TODO check that HOSTNAME start with xrootd-mgr,
# instead of equality
if [ "$HOSTNAME" = "$XROOTD_MANAGER" ]; then
    INSTANCE_NAME='manager'
else
    INSTANCE_NAME='worker'
fi
export INSTANCE_NAME

su qserv -c "sh /config-start/cmsd.sh"
