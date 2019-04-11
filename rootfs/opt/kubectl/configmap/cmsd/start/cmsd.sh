#!/bin/sh

# Start cmsd and xrootd inside pod
# Launch as qserv user

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

CONFIG_DIR="/config-etc"
XROOTD_CONFIG="$CONFIG_DIR/xrootd.cf"
XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"

# INSTANCE_NAME is required by xrdssi plugin to
# choose which type of queries to launch against metadata
if [ "$INSTANCE_NAME" = 'worker' ]; then
    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${XROOTD_DN}/1094"
    do
        echo "waiting for xrootd master (${XROOTD_DN})..."
        sleep 2
    done
    OPT_XRD_SSI="-l @libXrdSsiLog.so -+xrdssi $XRDSSI_CONFIG"
fi

# When at least one of the current pod's containers
# readiness health check pass, then dns name resolve.
until ping -c 1 ${HOSTNAME}.${QSERV_DOMAIN}; do
    echo "waiting for DNS (${HOSTNAME}.${QSERV_DOMAIN})..."
    sleep 2
done

# Start cmsd
#
echo "Start cmsd"
cmsd -c "$XROOTD_CONFIG" -n "$INSTANCE_NAME" -I v4 $OPT_XRD_SSI
