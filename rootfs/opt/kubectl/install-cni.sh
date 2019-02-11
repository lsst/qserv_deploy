#!/bin/sh

# LSST Data Management System
# Copyright 2014 LSST Corporation.
#
# This product includes software developed by the
# LSST Project (http://www.lsst.org/).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the LSST License Statement and
# the GNU General Public License along with this program.  If not,
# see <http://www.lsstcorp.org/LegalNotices/>.

# Install a hard-coded CNI plugin, for network
# WARN: update 'kubeadm init' command when switching CNI plugin

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

usage() {
    cat << EOD

Usage: `basename $0` <cni-plugin>

  Install <cni-plugin> on current Kubernetes cluster.

  Pre-requisites: a valid kubeconfig file is required

EOD
}

if [ $# -ne 1 ] ; then
    usage
    exit 2
fi

CNI_PLUGIN="$1"

counter=0
while ! kubectl get componentstatuses
do
    if [ "$counter" -lt 10 ]
    then
        echo "Wait for master to be up"
        sleep 1
    else
        echo "ERROR: master startup failed"
        exit 1
    fi
    counter=$((counter+1))
done

echo "Install $CNI network"

case "$CNI_PLUGIN" in
        calico)
            base_url="https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted"
            kubectl apply -f "$base_url/rbac-kdd.yaml"
            kubectl apply -f "$base_url/kubernetes-datastore/calico-networking/1.7/calico.yaml"
            exit
            ;;

        flannel)
            kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

            # Wait for flannel to be ready
            COUNT_GO_TPL='{{range .items}}{{printf "%v " .metadata.name}}{{end}}'
            NODE_COUNT=$(kubectl get nodes -o go-template="$COUNT_GO_TPL" | wc -w)
            while true
            do
                READY=$(kubectl get ds -n kube-system  kube-flannel-ds-amd64 \
                    -o go-template --template "{{.status.numberReady}}")
                if [ $READY -eq $NODE_COUNT ]; then
                    break
                else
                    echo "Wait for flannel daemonset to be READY"
                    sleep 2
                fi
            done
            ;;

        weave)
            KUBEVER=$(kubectl version | base64 | tr -d '\n')
            kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$KUBEVER"

            # Wait for Weave to be ready
            while true
            do
                READY=$(kubectl get daemonset --namespace=kube-system -l name=weave-net \
                    -o go-template --template "{{range .items}}{{.status.numberReady}}{{end}}")
                if [ $READY -ge 1 ]; then
                    break
                else
                    echo "Wait for weave-net daemonset to be READY"
                    sleep 2
                fi
            done
            ;;
esac
