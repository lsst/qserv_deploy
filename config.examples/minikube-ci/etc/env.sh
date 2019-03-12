# Description: allow to customize pods execution


# Container settings
# =====================

# Versions must match an existing container tag
MARIADB_VERSION="10.2.16"
QSERV_DEPLOY_VERSION="f7a7c00"
QSERV_VERSION="d7fc83f"
REPL_VERSION="tools-w.2018.16-556-g62efc42-dirty"

# Mariadb container image name
MARIADB_IMAGE="mariadb:${MARIADB_VERSION}"

# Qserv deploy container image name
QSERV_DEPLOY_IMAGE="qserv/deploy:${QSERV_DEPLOY_IMAGE}"

# Qserv container image name
QSERV_IMAGE="qserv/qserv:${QSERV_VERSION}"

# Replication system container image name
REPL_IMAGE="qserv/replica:${REPL_VERSION}"

# Advanced configuration
# ======================

# QSERV_CFG_DIR is a global variable

# Parameters related to infrastructure, used to compute worker number 
. "$QSERV_CFG_DIR/env-infra.sh"

WORKER_COUNT=${SIZE_WORKER:-$(echo $WORKERS | wc -w)}
