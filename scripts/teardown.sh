#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="admission-shield-lab"

echo ">> Tearing down Kind cluster '${CLUSTER_NAME}'..."
kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || true

echo ">> Cluster cleanly destroyed."
