# Kubernetes cheat sheet for Qserv

[Official k8s cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet)

# Pre-requisites

Get access to a Kubernetes cluster running Qserv, see [README](../README.md) 

# Interact with running pods

```shell
    # Get the containers list for pod 'czar-0'
    kubectl get pods czar-0 -o jsonpath='{.spec.containers[*].name}'

    # Get the xrootd container logs on pod czar-0
    kubectl logs czar-0 -c xrootd 

    # Open a shell on mariadb container on worker qserv-0
    kubectl exec -it qserv-0 -c mariadb bash
    
    #  
```

