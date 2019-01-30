#!/bin/bash

set -e

kubectl get pv  -o go-template --template='{{range .items}}{{printf "%v;%v\n" .spec.claimRef.name .spec.gcePersistentDisk.pdName}}{{end}}'