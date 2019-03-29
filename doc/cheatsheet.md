# Kubernetes cheat sheet for Qserv

[Official k8s cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet)

## Pre-requisites

Get access to a Kubernetes cluster running Qserv, see [README](../README.md) 

## Interact with running pods

```shell
    # Get the containers list for pod 'czar-0'
    kubectl get pods czar-0 -o jsonpath='{.spec.containers[*].name}'

    # Get the xrootd container logs on pod czar-0
    kubectl logs czar-0 -c xrootd 

    # Open a shell on mariadb container on worker qserv-0
    kubectl exec -it qserv-0 -c mariadb bash
```

## Update Qserv configuration

Update Qserv configuration by updating its related k8s configmaps.

```shell

    # Go to default configuration directory
    cd qserv_deploy/rootfs/opt/kubectl/configmap/

    # Go to the directory corresponding to a process/container
    cd xrootd

    # etc/ contains configuration file(s)
    # start/ contains startup script(s)
    
    # edit a configuration file
    vi etc/xrootd.cf

    # Launch qserv-deploy in development mode (-d option)
    ./qserv-deploy.sh -C "$QSERV_CFG_DIR" -d
    # Eventually stop Qserv
    qserv-stop
    # Start Qserv, new configuration will be applied for all xrootd pods
    qserv-start
```

## Launch commands directly on workers

```shell
    # Launch a SQL query on mariadb on worker qserv-10
    kubectl exec -it qserv-10 -c mariadb bash
    . /qserv/stack/loadLSST.bash
    setup qserv_distrib -t qserv-dev
    mysql --socket /qserv/data/mysql/mysql.sock --user=root --password="CHANGEME" -e "SHOW PROCESSLIST"
    exit

    # Install debug tools inside a container
    # NOTE: tools will be removed at next Qserv restart
    # WARN: being root inside a container is insecure but is useful for development mode
    kubectl exec -it qserv-10 -c mariadb bash
    # Eventually define proxy if needed
    export https_proxy="http://ccqservproxy.in2p3.fr:3128"
    yum install gdb bind-utils
    exit
```

## Interact with storage

```shell
    # Get persistent volume claims for Qserv pods
    kubectl get pvc -l app=qserv

    # Get persistent volumes for Qserv pods
    kubectl get pv -l app=qserv
```