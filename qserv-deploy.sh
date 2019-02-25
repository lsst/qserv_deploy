#!/bin/sh

# Wrapper for the Qserv deploy container
# Check for needed variables

# @author Benjamin Roziere <benjamin.roziere@clermont.in2p3.fr>

set -e

STABLE_VERSION="a44baeb" 

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options] [cmd]

  Available options:
    -C          Path to configuration directory (default to QSERV_CFG_DIR)
    -d          Run in development mode (i.e. mount source files on host)
    -h          This message
    -s          Do not attache host volume \$HOME/.ssh inside container

  Run a container with all the Qserv deployment tools inside.

  Pre-requisites: QSERV_CFG_DIR env variable can be defined and exported.

EOD
}

MOUNT_SSH=true

# get the options
while getopts C:dhs c ; do
    case $c in
        C) QSERV_CFG_DIR="$OPTARG" ;;
        d) QSERV_DEV=true ;;
        h) usage ; exit 0 ;;
        s) MOUNT_SSH=false ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ge 2 ] ; then
    usage
    exit 2
elif [ $# -eq 1 ]; then
    CMD=$1
fi

VERSION=${DEPLOY_VERSION:-$STABLE_VERSION}

if [ ! -d "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Incorrect QSERV_CFG_DIR parameter: \"$QSERV_CFG_DIR\""
    exit 1
fi

MOUNTS="-v $QSERV_CFG_DIR:/etc/qserv-deploy "

CONTAINER_HOME="/home/$USER"

if [ "$MOUNT_SSH" = true ]
then
    SSH_DIR="$HOME/.ssh"
    MOUNTS="$MOUNTS -v $SSH_DIR:$CONTAINER_HOME/.ssh"
fi

MOUNTS="$MOUNTS -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro"

GCLOUD_DIR="$QSERV_CFG_DIR/gcloud"
mkdir -p $GCLOUD_DIR
MOUNTS="$MOUNTS -v $GCLOUD_DIR:$CONTAINER_HOME/.config"

DOT_KUBE_DIR="$QSERV_CFG_DIR/dot-kube"
mkdir -p "$DOT_KUBE_DIR"
MOUNTS="$MOUNTS -v $DOT_KUBE_DIR:$CONTAINER_HOME/.kube"

MOUNTS="$MOUNTS -v $DIR/home/.bashrc:$CONTAINER_HOME/.bashrc"

echo "Starting Qserv deploy on cluster $QSERV_CFG_DIR"

if [ "$QSERV_DEV" = true ]; then
    echo "Running in development mode"
    MOUNTS="$MOUNTS -v $DIR/rootfs/opt:/opt"
fi

# Used with minikube to retrieve keys stored in $HOME/.minikube/
if [ "$MOUNT_DOT_MK" = true ]; then
    echo "Mounting $HOME/.minikube inside container"
    MOUNTS="$MOUNTS -v $HOME/.minikube:$HOME/.minikube"
fi

docker run -it --net=host --rm -l config-path=$QSERV_CFG_DIR \
    -e HOME="$CONTAINER_HOME" \
    --user=$(id -u):$(id -g $USER) \
    $MOUNTS \
    -w $CONTAINER_HOME \
    qserv/deploy:$VERSION $CMD
