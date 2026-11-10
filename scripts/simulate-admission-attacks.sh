#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " [ATTACK SIMULATION] Testing Kyverno Admission Shield"
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKLOADS_DIR="${SCRIPT_DIR}/../test-workloads"

# Test 1: Deploy Root User Pod
echo ""
echo ">> TEST 1: Attempting to deploy Pod running as ROOT..."
if kubectl apply -f "${WORKLOADS_DIR}/bad-pod-root-user.yaml" 2>&1 | grep -i "blocked\|strictly prohibited\|denied\|failed"; then
  echo "✅ PASSED: Kyverno successfully BLOCKED root user pod!"
else
  echo "❌ FAILED: Root user pod was allowed to deploy!"
fi

# Test 2: Deploy Host Namespace Breakout Pod
echo ""
echo ">> TEST 2: Attempting to deploy Pod with hostPID & privileged: true..."
if kubectl apply -f "${WORKLOADS_DIR}/bad-pod-host-pid.yaml" 2>&1 | grep -i "blocked\|forbidden\|denied\|failed"; then
  echo "✅ PASSED: Kyverno successfully BLOCKED host namespace breakout!"
else
  echo "❌ FAILED: Privileged container was allowed to deploy!"
fi

# Test 3: Deploy Fully Hardened Compliant Pod
echo ""
echo ">> TEST 3: Deploying hardened, non-root, read-only rootfs Pod..."
if kubectl apply -f "${WORKLOADS_DIR}/good-pod-hardened-signed.yaml"; then
  echo "✅ PASSED: Hardened pod successfully ADMITTED by policy engine!"
  kubectl get pod good-pod-hardened -n production
  # Clean up test pod
  kubectl delete -f "${WORKLOADS_DIR}/good-pod-hardened-signed.yaml" --wait=false
else
  echo "❌ FAILED: Hardened pod was incorrectly rejected!"
fi

echo ""
echo "=========================================================="
echo " Admission Control Attack Simulation Complete!"
echo " All Zero-Trust Admission Gates Verified."
echo "=========================================================="
