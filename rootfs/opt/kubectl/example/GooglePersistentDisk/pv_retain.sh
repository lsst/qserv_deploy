#!/bin/bash

set -e
set -x

PVS=$(kubectl get pv  -o go-template --template='{{range .items}}{{printf "%v " .metadata.name}}{{end}}')

for pv in $PVS
do
    kubectl patch pv "$pv" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' || echo "Not patched"
done
