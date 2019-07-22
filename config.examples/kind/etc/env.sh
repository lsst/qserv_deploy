# Description: allow to customize pods execution


# Container settings
# =====================

# Versions must match an existing container tag
MARIADB_VERSION="10.2.16"
QSERV_DEPLOY_VERSION="872c033"
QSERV_VERSION="9701693"
REPL_VERSION="tools-w.2018.16-556-g62efc42-dirty"

# Mariadb container image name
MARIADB_IMAGE="mariadb:${MARIADB_VERSION}"

# Qserv deploy container image name
QSERV_DEPLOY_IMAGE="qserv/deploy:${QSERV_DEPLOY_VERSION}"

# Qserv container image name
QSERV_IMAGE="qserv/qserv:${QSERV_VERSION}"

# Replication system container image name
REPL_IMAGE="qserv/replica:${REPL_VERSION}"

# Number of Qserv workers, depends on infrastructure
WORKER_COUNT=${SIZE_WORKER:-$(echo $WORKERS | wc -w)}

if [ -z "$WORKER_COUNT" ]
then
    echo "ERROR: undefined \$WORKER_COUNT"
    exit 2
fi
