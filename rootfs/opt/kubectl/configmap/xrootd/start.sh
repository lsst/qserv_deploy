#!/bin/sh

# Setup ulimit and launch xrootd startup script

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

if [ "$HOSTNAME" != "$CZAR" ]; then

# Increase limit for locked-in-memory size
MLOCK_AMOUNT=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 - 1000000)}')
ulimit -l "$MLOCK_AMOUNT"

CONFIG_DIR="/config-etc"
XROOTD_CONFIG="$CONFIG_DIR/xrootd.cf"
XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"
DATA_DIR="/qserv/data"
MYSQLD_DATA_DIR="$DATA_DIR/mysql"
MYSQLD_SOCKET="$MYSQLD_DATA_DIR/mysql.sock"

# Wait for mysql to be configured and started
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

# INSTANCE_NAME is required by xrdssi plugin to
# choose which type of queries to launch against metadata
if [ "$HOSTNAME" = "$CZAR" ]; then
    INSTANCE_NAME='master'
else
    INSTANCE_NAME='worker'
    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${CZAR_DN}/1094"
    do
        echo "waiting for xrootd master (${CZAR_DN})..."
        sleep 2
    done
fi

su qserv -c "sh /config-start/xrootd.sh"
