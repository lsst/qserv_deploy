#!/bin/sh

set -e
set -x

. "$QSERV_CFG_DIR/env-gke.sh"

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"
