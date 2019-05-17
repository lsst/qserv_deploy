#!/bin/sh

# Setup ulimit and launch xrootd startup script

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

export XROOTD_DN="${XROOTD_MANAGER}.${QSERV_DOMAIN}"

if [ "$HOSTNAME" = "$XROOTD_MANAGER" ]; then
    INSTANCE_NAME='master'
else
    INSTANCE_NAME='worker'
fi
export INSTANCE_NAME

if [ "$INSTANCE_NAME" = 'worker' ]; then

    # Increase limit for locked-in-memory size
    MLOCK_AMOUNT=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 - 1000000)}')
    ulimit -l "$MLOCK_AMOUNT"

fi

su qserv -c "sh /config-start/xrootd.sh"
