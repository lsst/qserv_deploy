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
if [ "$INSTANCE_NAME" != 'manager' ]; then

    XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"
    MYSQLD_SOCKET="/qserv/data/mysql/mysql.sock"

    # Wait for local mysql to be configured and started
    while true; do
        if mysql --socket "$MYSQLD_SOCKET" --user="$MYSQLD_USER_QSERV"  --skip-column-names \
            -e "SELECT CONCAT('Mariadb is up: ', version())"
        then
            break
        else
            echo "Wait for MySQL startup"
        fi
        sleep 2
    done

    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${XROOTD_DN}/1094"
    do
        echo "Wait for xrootd manager (${XROOTD_DN})"
        sleep 2
    done
    OPT_XRD_SSI="-l @libXrdSsiLog.so -+xrdssi $XRDSSI_CONFIG"

    # TODO move to /qserv/run/tmp when it is managed as a shared volume
    export VNID_FILE="/qserv/data/mysql/cms_vnid.txt"
    until test -e "$VNID_FILE"
    do
        echo "Wait for $VNID_FILE to be created by cmsd container"
        sleep 2
    done
fi

# Start xrootd
#
echo "Start xrootd"
xrootd -c "$XROOTD_CONFIG" -n "$INSTANCE_NAME" -I v4 $OPT_XRD_SSI
