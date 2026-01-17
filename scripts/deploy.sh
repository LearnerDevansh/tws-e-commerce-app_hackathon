#!/bin/bash

# Deployment script for EasyShop application
# Usage: ./deploy.sh [environment] [--skip-migration]

set -e

ENVIRONMENT=${1:-production}
NAMESPACE="easyshop"
SKIP_MIGRATION=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-migration)
            SKIP_MIGRATION=true
            shift
            ;;
    esac
done

echo "=========================================="
echo "🚀 EasyShop Deployment Script"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Skip Migration: $SKIP_MIGRATION"
echo "=========================================="

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    echo "✓ kubectl is installed and cluster is accessible"
}

# Function to check if namespace exists
check_namespace() {
    echo ""
    echo "Checking namespace..."
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    else
        echo "✓ Namespace $NAMESPACE exists"
    fi
}

# Function to apply Kubernetes manifests in order
apply_manifests() {
    echo ""
    echo "Applying Kubernetes manifests in order..."
    
    # Apply manifests in the correct order
    local manifest_order=(
        "01-namespace.yaml"
        "02-mongodb-pv.yaml"
        "03-mongodb-pvc.yaml"
        "04-configmap.yaml"
        "05-secrets.yaml"
        "06-mongodb-service.yaml"
        "07-mongodb-statefulset.yaml"
        "08-easyshop-deployment.yaml"
        "09-easyshop-service.yaml"
        "10-ingress.yaml"
        "11-hpa.yaml"
    )
    
    for manifest in "${manifest_order[@]}"; do
        local file="kubernetes/$manifest"
        if [ -f "$file" ]; then
            echo "  Applying $manifest..."
            kubectl apply -f "$file"
        else
            echo "  ⚠️  Warning: $manifest not found, skipping..."
        fi
    done
    
    echo "✅ All manifests applied successfully"
}

# Function to run database migration
run_migration() {
    if [ "$SKIP_MIGRATION" = true ]; then
        echo ""
        echo "⏭️  Skipping database migration"
        return
    fi
    
    echo ""
    echo "Running database migration..."
    
    # Delete existing migration job if it exists
    kubectl delete job db-migration -n "$NAMESPACE" --ignore-not-found=true
    
    # Wait a moment for cleanup
    sleep 2
    
    # Apply migration job
    kubectl apply -f kubernetes/12-migration-job.yaml
    
    # Wait for migration to complete
    echo "Waiting for migration to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/db-migration -n "$NAMESPACE" || {
        echo "❌ Migration job failed or timed out"
        kubectl logs -n "$NAMESPACE" job/db-migration --tail=50
        exit 1
    }
    
    echo "✅ Database migration completed successfully"
}

# Function to wait for MongoDB
wait_for_mongodb() {
    echo ""
    echo "Waiting for MongoDB to be ready..."
    kubectl rollout status statefulset/mongodb -n "$NAMESPACE" --timeout=5m
    echo "✅ MongoDB is ready"
}

# Function to wait for deployment
wait_for_deployment() {
    echo ""
    echo "Waiting for EasyShop deployment to be ready..."
    kubectl rollout status deployment/easyshop -n "$NAMESPACE" --timeout=5m
    echo "✅ Deployment is ready"
}

# Function to check application health
check_health() {
    echo ""
    echo "Checking application health..."
    
    # Get pod status
    echo ""
    echo "Pod Status:"
    kubectl get pods -n "$NAMESPACE"
    
    # Check if easyshop pods are running
    READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=easyshop -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -o "True" | wc -l)
    
    if [ "$READY_PODS" -gt 0 ]; then
        echo ""
        echo "✅ $READY_PODS EasyShop pod(s) are ready"
    else
        echo ""
        echo "❌ No EasyShop pods are ready"
        echo "Recent pod events:"
        kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
        exit 1
    fi
    
    # Get service information
    echo ""
    echo "Services:"
    kubectl get svc -n "$NAMESPACE"
    
    # Get ingress information
    echo ""
    echo "Ingress:"
    kubectl get ingress -n "$NAMESPACE"
}

# Function to display access information
display_access_info() {
    echo ""
    echo "=========================================="
    echo "🎉 Deployment completed successfully!"
    echo "=========================================="
    echo ""
    echo "Access the application:"
    echo "  🌐 Production URL: http://easyshop.devopsdock.site"
    echo "  🔧 Port Forward: kubectl port-forward -n $NAMESPACE svc/easyshop-service 3000:80"
    echo ""
    echo "Useful commands:"
    echo "  📊 View pods: kubectl get pods -n $NAMESPACE"
    echo "  📝 View logs: kubectl logs -n $NAMESPACE -l app=easyshop -f"
    echo "  🔍 Describe deployment: kubectl describe deployment easyshop -n $NAMESPACE"
    echo "  📈 View HPA: kubectl get hpa -n $NAMESPACE"
    echo ""
    echo "=========================================="
}

# Main deployment flow
main() {
    check_prerequisites
    check_namespace
    apply_manifests
    wait_for_mongodb
    run_migration
    wait_for_deployment
    check_health
    display_access_info
}

# Run main function
main
