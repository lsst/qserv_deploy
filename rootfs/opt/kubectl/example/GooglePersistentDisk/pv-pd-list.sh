#!/bin/bash

# Create a file with format "pvc;pd"

# @author Fabrice Jammes <fabrice.jammes@in2p3.fr>

set -e

kubectl get pv  -o go-template --template='{{range .items}}{{printf "%v;%v\n" .spec.claimRef.name .spec.gcePersistentDisk.pdName}}{{end}}'
