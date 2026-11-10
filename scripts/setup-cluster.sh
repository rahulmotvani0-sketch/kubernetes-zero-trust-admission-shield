#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " [SETUP] Kubernetes Zero-Trust Admission Shield Cluster"
echo "=========================================================="

CLUSTER_NAME="admission-shield-lab"

# 1. Verify Prerequisites
command -v kind >/dev/null 2>&1 || { echo "Error: 'kind' is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: 'kubectl' is required but not installed."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "Error: 'helm' is required but not installed."; exit 1; }

# 2. Create Kind Cluster if not exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo ">> Kind cluster '${CLUSTER_NAME}' already running."
else
  echo ">> Creating Kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
fi

# 3. Create Namespaces
echo ">> Provisioning namespaces..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# 4. Install Kyverno via Helm
echo ">> Adding Kyverno Helm repository..."
helm repo add kyverno https://kyverno.github.io/kyverno/ || true
helm repo update

echo ">> Installing/Upgrading Kyverno Admission Controller..."
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set replicaCount=1 \
  --wait

# 5. Apply Kyverno Cluster Policies
echo ">> Applying Zero-Trust Admission Policies..."
kubectl apply -f ../policies/

echo ">> Waiting for policies to become ready..."
kubectl wait --for=condition=Ready clusterpolicy --all --timeout=60s

echo "=========================================================="
echo " Admission Shield Cluster Ready & Hardened!"
echo "=========================================================="
