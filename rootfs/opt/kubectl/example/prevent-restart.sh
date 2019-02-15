#!/bin/sh

PODS_YAML="/tmp/pods.yaml"

kubectl delete statefulsets.apps --selector=app=qserv --cascade=false

kubectl get pods --selector=app=qserv -o yaml --export | sed "s/restartPolicy: Always/restartPolicy: Never/" > "$PODS_YAML" 

kubectl delete pods --selector=app=qserv

kubectl apply -f "$PODS_YAML"

# PODS=$(kubectl get pods --selector=app=qserv -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}")
# for pod in $PODS
# do
#   kubectl patch pods "$pod" -p '{"spec":{"restartPolicy":"Never"}}' || echo "Not patched"
# done
