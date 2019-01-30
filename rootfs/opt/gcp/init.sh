#!/bin/bash

. "$QSERV_CFG_DIR/env-gke.sh"

gcloud auth login
gcloud config set project $PROJECT
