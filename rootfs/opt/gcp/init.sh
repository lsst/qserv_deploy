#!/bin/bash

. "$QSERV_CFG_DIR/env-infra.sh"

gcloud auth login
gcloud config set project $PROJECT
