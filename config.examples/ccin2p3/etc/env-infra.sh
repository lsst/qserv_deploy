# Parameters related to CC-IN2P3 bare-metal cluster

# Size of memory for xrootd worker pod(s)
WKR_XROOTD_MEM_LIMIT="11Gi"
# Amount of memlock-able memory in bits
WKR_XROOTD_MLOCK="10000000"

# All host have same prefix
HOSTNAME_TPL="ccqserv"

# First and last id for worker node names
WORKER_FIRST_ID=126
WORKER_LAST_ID=149

# Used for ssh access
MASTER="${HOSTNAME_TPL}125"

# Used for ssh access
WORKERS=$(seq --format "${HOSTNAME_TPL}%g" \
    --separator=" " "$WORKER_FIRST_ID" "$WORKER_LAST_ID")

# Used for ssh access to Kubernetes master
ORCHESTRATOR="${HOSTNAME_TPL}km2"

# Host path for local volumes
LOCAL_VOLUMES_PATH="/qserv/desc"
