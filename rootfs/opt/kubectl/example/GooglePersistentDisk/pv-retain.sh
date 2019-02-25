#!/bin/bash

# Patch all pvs with persistentVolumeReclaimPolicy=Retain
# so that their related pd is retained on pv deletion

# @author Fabrice Jammes <fabrice.jammes@in2p3.fr>

set -e
# set -x

PVS=$(kubectl get pv  -o go-template --template='{{range .items}}{{printf "%v " .metadata.name}}{{end}}')

for pv in $PVS
do
    kubectl patch pv "$pv" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' || echo "Not patched"
done
