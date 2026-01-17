#!/bin/bash

# Health Check Script for EasyShop
# Usage: ./health-check.sh

set -e

NAMESPACE="easyshop"
APP_URL="http://easyshop.devopsdock.site"

echo "=========================================="
echo "🏥 EasyShop Health Check"
echo "=========================================="

# Function to check namespace
check_namespace() {
    echo ""
    echo "Checking namespace..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "✅ Namespace '$NAMESPACE' exists"
    else
        echo "❌ Namespace '$NAMESPACE' does not exist"
        exit 1
    fi
}

# Function to check deployments
check_deployments() {
    echo ""
    echo "Checking deployments..."
    
    DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$DEPLOYMENTS" ]; then
        echo "❌ No deployments found"
        return 1
    fi
    
    for deployment in $DEPLOYMENTS; do
        READY=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        DESIRED=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        
        if [ "$READY" = "$DESIRED" ]; then
            echo "✅ Deployment '$deployment': $READY/$DESIRED replicas ready"
        else
            echo "⚠️  Deployment '$deployment': $READY/$DESIRED replicas ready"
        fi
    done
}

# Function to check statefulsets
check_statefulsets() {
    echo ""
    echo "Checking statefulsets..."
    
    STATEFULSETS=$(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$STATEFULSETS" ]; then
        echo "ℹ️  No statefulsets found"
        return 0
    fi
    
    for sts in $STATEFULSETS; do
        READY=$(kubectl get statefulset "$sts" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        DESIRED=$(kubectl get statefulset "$sts" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        
        if [ "$READY" = "$DESIRED" ]; then
            echo "✅ StatefulSet '$sts': $READY/$DESIRED replicas ready"
        else
            echo "⚠️  StatefulSet '$sts': $READY/$DESIRED replicas ready"
        fi
    done
}

# Function to check pods
check_pods() {
    echo ""
    echo "Checking pods..."
    
    kubectl get pods -n "$NAMESPACE"
    
    echo ""
    TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
    RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers | wc -l)
    
    echo "Total pods: $TOTAL_PODS"
    echo "Running pods: $RUNNING_PODS"
    
    if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
        echo "✅ All pods are running"
    else
        echo "⚠️  Not all pods are running"
        
        echo ""
        echo "Pods with issues:"
        kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running
    fi
}

# Function to check services
check_services() {
    echo ""
    echo "Checking services..."
    
    kubectl get svc -n "$NAMESPACE"
    
    SERVICES=$(kubectl get svc -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$SERVICES" ]; then
        echo "❌ No services found"
        return 1
    fi
    
    echo "✅ Services are configured"
}

# Function to check ingress
check_ingress() {
    echo ""
    echo "Checking ingress..."
    
    INGRESS=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$INGRESS" ]; then
        echo "⚠️  No ingress found"
        return 0
    fi
    
    kubectl get ingress -n "$NAMESPACE"
    
    echo "✅ Ingress is configured"
}

# Function to check PVCs
check_pvcs() {
    echo ""
    echo "Checking Persistent Volume Claims..."
    
    PVCS=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$PVCS" ]; then
        echo "ℹ️  No PVCs found"
        return 0
    fi
    
    kubectl get pvc -n "$NAMESPACE"
    
    BOUND_PVCS=$(kubectl get pvc -n "$NAMESPACE" --field-selector=status.phase=Bound --no-headers | wc -l)
    TOTAL_PVCS=$(kubectl get pvc -n "$NAMESPACE" --no-headers | wc -l)
    
    if [ "$BOUND_PVCS" -eq "$TOTAL_PVCS" ]; then
        echo "✅ All PVCs are bound"
    else
        echo "⚠️  Not all PVCs are bound"
    fi
}

# Function to check HPA
check_hpa() {
    echo ""
    echo "Checking Horizontal Pod Autoscaler..."
    
    HPA=$(kubectl get hpa -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$HPA" ]; then
        echo "ℹ️  No HPA configured"
        return 0
    fi
    
    kubectl get hpa -n "$NAMESPACE"
    
    echo "✅ HPA is configured"
}

# Function to check application endpoint
check_endpoint() {
    echo ""
    echo "Checking application endpoint..."
    
    if command -v curl &> /dev/null; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL" --max-time 10 || echo "000")
        
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ Application is accessible at $APP_URL (HTTP $HTTP_CODE)"
        else
            echo "⚠️  Application returned HTTP $HTTP_CODE"
        fi
    else
        echo "ℹ️  curl not available, skipping endpoint check"
    fi
}

# Function to check recent events
check_events() {
    echo ""
    echo "Recent events (last 10)..."
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
}

# Function to display resource usage
check_resources() {
    echo ""
    echo "Resource usage..."
    
    if command -v kubectl &> /dev/null; then
        kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "ℹ️  Metrics server not available"
    fi
}

# Function to generate summary
generate_summary() {
    echo ""
    echo "=========================================="
    echo "📊 Health Check Summary"
    echo "=========================================="
    
    # Count issues
    ISSUES=0
    
    # Check if all pods are running
    TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$RUNNING_PODS" -ne "$TOTAL_PODS" ]; then
        ((ISSUES++))
    fi
    
    if [ "$ISSUES" -eq 0 ]; then
        echo "✅ Overall Status: HEALTHY"
    else
        echo "⚠️  Overall Status: ISSUES DETECTED ($ISSUES)"
    fi
    
    echo ""
    echo "Application URL: http://easyshop.devopsdock.site"
    echo "Namespace: $NAMESPACE"
    echo "Total Pods: $TOTAL_PODS"
    echo "Running Pods: $RUNNING_PODS"
    echo "=========================================="
}

# Main health check flow
main() {
    check_namespace
    check_deployments
    check_statefulsets
    check_pods
    check_services
    check_ingress
    check_pvcs
    check_hpa
    check_endpoint
    check_events
    check_resources
    generate_summary
}

# Run main function
main
