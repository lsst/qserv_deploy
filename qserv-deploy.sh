#!/bin/sh

# Wrapper for the Qserv deploy container
# Check for needed variables

# @author Benjamin Roziere <benjamin.roziere@clermont.in2p3.fr>

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options] [cmd]

  Available options:
    -C <cfgdir>  Path to configuration directory (default to \$QSERV_CFG_DIR),
    -d           Run in development mode (i.e. mount source files on host)
    -g <dir>     Path to gcloud configuration directory
                 Default to <cfgdir>/dot-config
    -h           This message
    -M           Mount \$HOME/.minikube inside container
    -s <dir>     Path to ssh configuration directory.
                 Default to \$HOME/.ssh

  Run a container with all the Qserv deployment tools inside.

  Pre-requisites:
    - QSERV_CFG_DIR env variable can be defined and exported.
    - Host volumes must be reachables by docker daemon

EOD
}


# get the options
while getopts C:dg:hMs: c ; do
    case $c in
        C) QSERV_CFG_DIR="$OPTARG" ;;
        d) QSERV_DEV=true ;;
        g) GCLOUD_DIR="$OPTARG" ;;
        h) usage ; exit 0 ;;
        M) MOUNT_DOT_MK=true ;;
        s) SSH_DIR="$OPTARGS" ;;
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

if [ -z "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Unset QSERV_CFG_DIR parameter \
(set it as env variable or use -C option)"
    usage
    exit 1
elif [ ! -d "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Non-existing directory for QSERV_CFG_DIR parameter: \"$QSERV_CFG_DIR\""
    usage
    exit 1
fi

# Get qserv_deploy image name
. "$QSERV_CFG_DIR/etc/env.sh"

if [ -z "$GCLOUD_DIR" ];
then
    GCLOUD_DIR="$QSERV_CFG_DIR/dot-config"
fi

if [ -z "$SSH_DIR" ];
then
    SSH_DIR="$HOME/.ssh"
fi

TMP_DIR="$QSERV_CFG_DIR/tmp"

MOUNTS="-v $QSERV_CFG_DIR/etc:/etc/qserv-deploy "

mkdir -p $TMP_DIR
MOUNTS="$MOUNTS -v $TMP_DIR:/tmp/qserv-deploy "

CONTAINER_HOME="/home/$USER"

mkdir -p $GCLOUD_DIR
MOUNTS="$MOUNTS -v $GCLOUD_DIR:$CONTAINER_HOME/.config"
MOUNTS="$MOUNTS -v $SSH_DIR:$CONTAINER_HOME/.ssh"

MOUNTS="$MOUNTS -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro"

DOT_KUBE_DIR="$QSERV_CFG_DIR/dot-kube"
mkdir -p "$DOT_KUBE_DIR"
MOUNTS="$MOUNTS -v $DOT_KUBE_DIR:$CONTAINER_HOME/.kube"

MOUNTS="$MOUNTS -v $DIR/homefs/.bashrc:$CONTAINER_HOME/.bashrc"

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

docker run -it --net=host --rm -l config-path="$QSERV_CFG_DIR" \
    -e HOME="$CONTAINER_HOME" \
    --user=$(id -u):$(id -g "$USER") \
    $MOUNTS \
    -w "$CONTAINER_HOME" \
    "$QSERV_DEPLOY_IMAGE" $CMD
