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

# INSTANCE_NAME is required by xrdssi plugin to
# choose which type of queries to launch against metadata
if [ "$INSTANCE_NAME" = 'manager' ]; then

    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/1094"
    do
        echo "Wait for xrootd manager (${XROOTD_DN})..."
        sleep 2
    done

else

    MYSQLD_SOCKET="/qserv/data/mysql/mysql.sock"
    XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"

    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${XROOTD_DN}/1094"
    do
        echo "Wait for xrootd manager (${XROOTD_DN})..."
        sleep 2
    done
    OPT_XRD_SSI="-l @libXrdSsiLog.so -+xrdssi $XRDSSI_CONFIG"

    # Write worker id to file
    while true
    do
        WORKER=$(mysql --socket "$MYSQLD_SOCKET" --batch \
        --skip-column-names --user="$MYSQLD_USER_QSERV" -e "SELECT id FROM qservw_worker.Id;")
        if [ -n "$WORKER" ]; then
            break
        fi
    done
    export VNID_FILE="/qserv/data/mysql/cms_vnid.txt"
    echo "$WORKER" > "$VNID_FILE"
fi

# Start cmsd
#
echo "Start cmsd"
cmsd -c "$XROOTD_CONFIG" -n "$INSTANCE_NAME" -I v4 $OPT_XRD_SSI
