# Directory containing infrastructure specification
# (ssh credentials, machine names)
CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-$HOME/.lsst/qserv-cluster}"

# ssh credentials, optional
SSH_CFG="$CLUSTER_CONFIG_DIR/ssh_config"

# ssh option for using configuration file
if [ -r "$SSH_CFG" ]; then
    SSH_CFG_OPT="-F $SSH_CFG"
else
    SSH_CFG_OPT=
fi

# Machine names
ENV_INFRASTRUCTURE_FILE="$CLUSTER_CONFIG_DIR/env-infrastructure.sh"
. "$ENV_INFRASTRUCTURE_FILE"

# GNU parallel ssh configuration
PARALLEL_SSH_CFG="$CLUSTER_CONFIG_DIR/sshloginfile"

