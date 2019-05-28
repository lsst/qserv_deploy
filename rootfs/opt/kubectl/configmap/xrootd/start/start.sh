#!/bin/sh

# Setup ulimit and launch xrootd startup script

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

if [ "$HOSTNAME" != "$CZAR" ]; then

    # Increase limit for locked-in-memory size
    MLOCK_AMOUNT=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 - 4000000)}')
    ulimit -l "$MLOCK_AMOUNT"

fi

if  [ "$HOSTNAME" = "qserv-10" ]; then
    export https_proxy="http://ccqservproxy.in2p3.fr:3128"
    export http_proxy="http://ccqservproxy.in2p3.fr:3128"
    yum install -y valgrind
fi
su qserv -c "sh /config-start/xrootd.sh"
