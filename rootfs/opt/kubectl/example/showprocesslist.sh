#!/bin/bash

# Run SQL query on all pods 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

PODS=$(kubectl get pods -l 'app=qserv,tier in (master, worker)' -o go-template="{{range .items}}{{.metadata.name}} {{end}}")


DB=mysql

SQL="SHOW PROCESSLIST;"
PASSWORD="CHANGEME"

parallel "kubectl exec {} -c mariadb -- \
    bash -c \"hostname && 
    . /qserv/stack/loadLSST.bash && \
    setup mariadbclient && \
    mysql -S /qserv/data/mysql/mysql.sock \
    --user=root --password=$PASSWORD $DB \
    -e '$SQL'\"" ::: $PODS
