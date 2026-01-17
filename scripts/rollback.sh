#!/bin/bash

# Rollback script for EasyShop application
# Usage: ./rollback.sh [revision]

set -e

NAMESPACE="easyshop"
DEPLOYMENT="easyshop"
REVISION=${1:-}

echo "🔄 Rolling back EasyShop deployment..."

# Function to show deployment history
show_history() {
    echo "Deployment history:"
    kubectl rollout history deployment/"$DEPLOYMENT" -n "$NAMESPACE"
}

# Function to rollback to specific revision
rollback_to_revision() {
    if [ -n "$REVISION" ]; then
        echo "Rolling back to revision $REVISION..."
        kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE" --to-revision="$REVISION"
    else
        echo "Rolling back to previous revision..."
        kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE"
    fi
}

# Function to wait for rollback
wait_for_rollback() {
    echo "Waiting for rollback to complete..."
    kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=5m
}

# Function to verify rollback
verify_rollback() {
    echo "Verifying rollback..."
    
    # Get current revision
    CURRENT_REVISION=$(kubectl get deployment/"$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
    echo "Current revision: $CURRENT_REVISION"
    
    # Check pod status
    kubectl get pods -n "$NAMESPACE" -l app=easyshop
    
    # Check if pods are running
    READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=easyshop -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
    
    if [ "$READY_PODS" -gt 0 ]; then
        echo "✅ Rollback successful! $READY_PODS pod(s) are ready"
    else
        echo "❌ Rollback verification failed"
        exit 1
    fi
}

# Main rollback flow
main() {
    show_history
    echo ""
    
    if [ -z "$REVISION" ]; then
        read -p "Enter revision number to rollback to (or press Enter for previous): " REVISION
    fi
    
    rollback_to_revision
    wait_for_rollback
    verify_rollback
    
    echo ""
    echo "🎉 Rollback completed successfully!"
}

# Run main function
main
