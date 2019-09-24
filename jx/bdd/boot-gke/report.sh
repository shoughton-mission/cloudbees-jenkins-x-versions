#!/usr/bin/env bash
set -euo pipefail
set -x

if [ $# -ne 1 ]; then
    echo "Please provide the report file"
    exit -1
fi
REPORT=$1

# activate the GCP service account before uploading the report
gcloud auth activate-service-account --key-file $GKE_SA

jx step stash \
    -c tests \
    -p "${REPORT}" \
    --bucket-url gs://cjxd-release-logs
