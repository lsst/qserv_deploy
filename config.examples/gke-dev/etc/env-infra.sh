# Parameters related to GKE instructure

# Size of memory for czar pod(s)
CZAR_DB_MEM_REQUEST="10Gi"

# Size of GKE volumes for all pods
STORAGE_SIZE="1Gi"

MTYPE_CZAR="n1-standard-4"
MTYPE_WORKER="n1-standard-2"

CLUSTER="qserv-fjammes"
PROJECT="neural-theory-215601"

REGION="us-central1"
ZONE="us-central1-a"

SIZE_CZAR=1
SIZE_WORKER=2

PREEMPTIBLE_OPT="--preemptible"

GKE=true
