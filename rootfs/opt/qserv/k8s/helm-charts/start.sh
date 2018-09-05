#!/bin/sh

# Deploy Qserv StatefulSet on Kubernetes cluster

# @author  Benjamin Roziere, IN2P3
# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

HELM_CHART="qserv"

CFG_DIR="${DIR}/yaml"
RESOURCE_DIR="${DIR}/resource"
CONFIGMAP_DIR="${DIR}/configmap"
TMP_DIR=$(mktemp -d --suffix=-qserv-deploy-yaml)

# For in2p3 cluster: k8s schema cache must not be on AFS
CACHE_DIR=$(mktemp -d --suffix=-kube-$USER)
CACHE_OPT="--cache-dir=$CACHE_DIR/schema"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options]

  Available options:
    -h          this message

  Deploy Qserv on Kubernetes

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

YAML_TPL="${CFG_DIR}/statefulset.yaml.tpl"
YAML_FILE="${TMP_DIR}/statefulset.yaml"
INI_FILE="${TMP_DIR}/statefulset.ini"

echo "Create kubernetes configmaps for Qserv"

QSERV_MASTER="qserv-0"
QSERV_DOMAIN="qserv"
QSERV_MASTER_DN="${QSERV_MASTER}.${QSERV_DOMAIN}"

kubectl delete configmap --ignore-not-found=true config-master
kubectl create configmap config-master --from-literal=qserv_master="$QSERV_MASTER" \
    --from-literal=qserv_domain="$QSERV_DOMAIN" \
    --from-literal=qserv_master_dn="$QSERV_MASTER_DN"

kubectl delete configmap --ignore-not-found=true config-dot-lsst
kubectl create configmap --from-file="$CONFIGMAP_DIR/dot-lsst" config-dot-lsst

kubectl delete configmap --ignore-not-found=true config-mariadb-configure
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/mariadb-configure.sh" config-mariadb-configure

kubectl delete configmap --ignore-not-found=true config-mariadb-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/start.sh" config-mariadb-start

kubectl delete configmap --ignore-not-found=true config-sql-master
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/master" config-sql-master

kubectl delete configmap --ignore-not-found=true config-sql-worker
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/worker" config-sql-worker

kubectl delete configmap --ignore-not-found=true config-mariadb-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/etc/my.cnf" config-mariadb-etc

kubectl delete configmap --ignore-not-found=true config-proxy-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/etc" config-proxy-etc

kubectl delete configmap --ignore-not-found=true config-proxy-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/start.sh" config-proxy-start

kubectl delete configmap --ignore-not-found=true config-proxy-probe
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/probe.sh" config-proxy-probe

kubectl delete configmap --ignore-not-found=true config-wmgr-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/etc" config-wmgr-etc 

kubectl delete configmap --ignore-not-found=true config-wmgr-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/start.sh" config-wmgr-start

kubectl delete configmap --ignore-not-found=true config-xrootd-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/start.sh" config-xrootd-start

kubectl delete configmap --ignore-not-found=true config-xrootd-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/etc" config-xrootd-etc

echo "Create kubernetes secrets for Qserv"
kubectl delete secret --ignore-not-found=true secret-wmgr
kubectl create secret generic secret-wmgr \
        --from-file="$CONFIGMAP_DIR/wmgr/wmgr.secret"


echo "Create nodeport service for Qserv"
kubectl apply $CACHE_OPT -f ${CFG_DIR}/qserv-nodeport-service.yaml

echo "Create kubernetes pod for Qserv statefulset"

REPLICAS=$(echo $WORKERS $MASTER | wc -w)

cat << EOF > "$INI_FILE"
[spec]
host_data_dir: $HOST_DATA_DIR
host_tmp_dir: $HOST_TMP_DIR
replicas: $REPLICAS
image: $CONTAINER_IMAGE
EOF

helm upgrade -i qserv qserv
