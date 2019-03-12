# Parameters related to GKE instructure

# Size of memory for czar pod(s)
MEM_REQUEST="50G"

# Size of GKE volumes for all pods
STORAGE_SIZE="3Ti"

MTYPE_CZAR="n1-standard-16"
MTYPE_DEFAULT="n1-standard-8"
MTYPE_WORKER="n1-standard-8"

CLUSTER="qserv-desc"
CLUSTER_VERSION="1.11.7-gke.4"
PROJECT="neural-theory-215601"

SCOPE="https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"

REGION="us-central1"
SUBNETWORK="projects/$PROJECT/regions/$REGION/subnetworks/default"
ZONE="us-central1-a"

SIZE_DEFAULT=1
SIZE_CZAR=1
SIZE_WORKER=2

GKE=true
