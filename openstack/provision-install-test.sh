#!/bin/bash

# Test script which performs the following tasks:

# Create image
# Boot instances
# Launch Qserv containers
# Lauch integration tests

# @author  Oualid Achbal, IN2P3
# @author  Fabrice Jammes, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h          this message
    -c          update CentOS7/Docker snapshot
    -L          run S15 queries
    -k          launch Qserv integration test using kubernetes
    -p          provision Qserv cluster on Openstack
    -s          launch Qserv integration test using shmux
                -k has priority on -s

  Create up to date CentOS7 snapshot and use it to provision Qserv cluster on
  Openstack, then install Qserv and launch integration test on it.
  If no option provided, use '-p -S' by default.


  Pre-requisites: Openstack RC file need to be sourced.

EOD
}

# get the options
while getopts hckLpsS c ; do
    case $c in
        h) usage ; exit 0 ;;
        c) CREATE="TRUE" ;;
        k) KUBERNETES="TRUE" ;;
        L) LARGE="TRUE" ;;
        p) PROVISION="TRUE" ;;
        s) SHMUX="TRUE" ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

if [ "$OPTIND" -eq 1 ]; then
    PROVISION="TRUE"
fi

# Check if openstack connection parameters are available
if [ -z "$OS_PROJECT_NAME" ]; then
    echo "ERROR: Openstack resource file not sourced"
    exit 1
fi

# Choose the configuration file which contains instance parameters
CONF_FILE="${DIR}/${OS_PROJECT_NAME}.conf"

if [ -n "$CREATE" ]; then
    echo "Create up to date snapshot image"
    "$DIR/create-image.py" --cleanup --config "$CONF_FILE" -vv
fi

CONFIG_DIR="$HOME/.lsst/qserv-cluster"
mkdir -p "$CONFIG_DIR"
if [ -n "$PROVISION" ]; then
    echo "Provision Qserv cluster on Openstack"
    "$DIR/provision-qserv.py" --cleanup \
        --config "$CONF_FILE" \
        -vv
	ln -f "$DIR/ssh_config" "$CONFIG_DIR"
	ln -f "$DIR/env-infrastructure.sh" "$CONFIG_DIR"
    "$DIR/../k8s/sysadmin/create-gnuparallel-slf.sh"
fi

if [ -n "$KUBERNETES" ]; then
	K8S_DIR="$DIR/../k8s"
    ENV_FILE="$CONFIG_DIR/env.sh"
    cp "$K8S_DIR/env.example.sh" "$ENV_FILE"

    if [ -n "$DEPLOY_VERSION" ]; then
        sed -i "s,DEPLOY_VERSION=dev,DEPLOY_VERSION=$DEPLOY_VERSION," "$ENV_FILE"
	fi

    if [ -n "$LARGE" ]; then
        sed -i "s,# HOST_DATA_DIR=/qserv/data,HOST_DATA_DIR=/mnt/qserv/data," \
            "$ENV_FILE"
    fi

	# Trigger special behaviour for Openstack
	export OPENSTACK=true
	"$K8S_DIR/full-start.sh"

    if [ -n "$LARGE" ]; then
        echo "Launch large scale tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-large-scale-tests.sh"
    else
        echo "Launch multinode tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-multinode-tests.sh"
    fi

elif [ -n "$SHMUX" ]; then

    echo "Launch integration tests using shmux"

    # Warning : if  multinode tests failed save your ~/.ssh/config
    # your old ~/.ssh/config is in ~/.ssh/config.backup

    DATE=$(date +%Y%m%d_%H-%M-%S)
    SSH_CONFIG="$HOME/.ssh/config"
    SSH_CONFIG_BACKUP="$SSH_CONFIG.backup.${DATE}"
    if [ -f "$SSH_CONFIG" ]; then
        echo  "WARN: backuping $SSH_CONFIG to $SSH_CONFIG_BACKUP"
        mv "$SSH_CONFIG" "$SSH_CONFIG_BACKUP"
    fi
    cp "$DIR/ssh_config" ~/.ssh/config
	if [ -z "$QSERV_DIR" ]; then
        echo "ERROR: undefined \$QSERV_DIR"
	fi
    cd $SQERV_DIR/admin/tools/docker/deployment/parallel

	echo "ERROR shmux version is no more supported and will be soon removed"
	exit 1
    cp env.example.sh "$ENV_FILE"
    . "$DIR/env-infrastructure.sh"
    sed -i "s/# MASTER_FORMAT=\"lsst-qserv-master%02g\"/MASTER_FORMAT=\"${HOSTNAME_TPL}master-%g\"/" "$ENV_FILE"
    sed -i "s/HOSTNAME_FORMAT=\"qserv%g.domain.org\"/HOSTNAME_FORMAT=\"${HOSTNAME_TPL}worker-%g\"/" "$ENV_FILE"
    sed -i "s/MASTER_ID=0/MASTER_ID=1/" "$ENV_FILE"
    sed -i "s/WORKER_LAST_ID=3/WORKER_LAST_ID=${WORKER_LAST_ID}/" "$ENV_FILE"

    if [ -n "$LARGE" ]; then
        sed -i "s,# HOST_DATA_DIR=/qserv/data,HOST_DATA_DIR=/mnt/qserv/data," "$ENV_FILE"
        ./run.sh
        ./run-large-scale-tests.sh
    else
        echo "Launch multinode tests"
        ./run-multinode-tests.sh
    fi

    if [ -f "$SSH_CONFIG_BACKUP" ]; then
        echo  "Restoring backup of $SSH_CONFIG"
        mv "$SSH_CONFIG_BACKUP" "$SSH_CONFIG"
    fi
fi
