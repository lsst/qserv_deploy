# Description: allow to customize pods execution


# Container settings
# =====================

MARIADB_VERSION=10.2.16

# VERSION is relative to Qservi/Repl repository, it can be:
#  - a git ticket branch but with _ instead of /
#    example: tickets_DM-7139, or dev
#  - a git hash
QSERV_VERSION=d7fc83f
REPL_VERSION=tools-w.2018.16-556-g62efc42-dirty

# Mariadb container image name
MARIADB_IMAGE="mariadb:${MARIADB_VERSION}"

# Qserv container image name
QSERV_IMAGE="qserv/qserv:${QSERV_VERSION}"

# Replication system container image name
REPL_IMAGE="qserv/replica:${REPL_VERSION}"

# Advanced configuration
# ======================

# QSERV_CFG_DIR is a global variable

# FIXME: infrastructure should be abstracted from k8s
# Parameters related to infrastructure, used to place containers:
# - node hostnames
. "$QSERV_CFG_DIR/env-infra.sh"

WORKER_COUNT=${SIZE_WORKER:-$(echo $WORKERS | wc -w)}
