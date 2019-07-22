#!/bin/sh

# Start cmsd or
# setup ulimit and start xrootd

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

usage() {
    cat << EOD

Usage: `basename $0` [options] [cmd]

  Available options:
    -S <service> Service to start, default to xrootd

  Start cmsd or setup ulimit and start xrootd.
EOD
}

service=xrootd

# get the options
while getopts S: c ; do
    case $c in
        S) service="$OPTARG" ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

export XROOTD_DN="${XROOTD_MANAGER}.${QSERV_DOMAIN}"

if hostname | egrep "^xrootd-mgr-[0-9]+"
then
    INSTANCE_NAME='manager'
else
    INSTANCE_NAME='worker'
fi
export INSTANCE_NAME

if [ "$service" = "xrootd" -a "$INSTANCE_NAME" = 'worker' ]; then

    # Increase limit for locked-in-memory size
    if [ -z "${MLOCK_AMOUNT}" ]; then
        MLOCK_AMOUNT=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 - 4000000)}')
    fi
    ulimit -l "$MLOCK_AMOUNT"

fi

su qserv -c "sh /config-start/$service.sh"
