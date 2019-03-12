#!/bin/sh

set -e

. "$QSERV_CFG_DIR/env-infra.sh"

# Creates a GKE cluster
gcloud config set project "$PROJECT"
<<<<<<< HEAD
gcloud beta container --project "$PROJECT" clusters create "$CLUSTER" --zone "$ZONE" \
    --no-enable-basic-auth --cluster-version "1.12.5-gke.5" --machine-type "$MTYPE_WORKER" \
    --image-type "COS" --disk-type "pd-standard" --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    $PREEMPTIBLE_OPT --num-nodes "$SIZE_WORKER" \
    --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias \
    --network "projects/$PROJECT/global/networks/default" \
    --subnetwork "projects/$PROJECT/regions/$REGION/subnetworks/default" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair
