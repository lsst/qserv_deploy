#!/bin/sh

set -e
set -x

. "$QSERV_CFG_DIR/env-infra.sh"

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"
