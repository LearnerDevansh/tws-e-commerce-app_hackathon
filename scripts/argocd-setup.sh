#!/bin/bash

# ArgoCD Setup Script for EasyShop
# Usage: ./argocd-setup.sh

set -e

ARGOCD_NAMESPACE="argocd"
APP_NAME="easyshop"

echo "=========================================="
echo "🚀 ArgoCD Setup for EasyShop"
echo "=========================================="

# Function to check if ArgoCD is installed
check_argocd_installed() {
    echo "Checking if ArgoCD is installed..."
    
    if kubectl get namespace "$ARGOCD_NAMESPACE" &> /dev/null; then
        echo "✓ ArgoCD namespace exists"
        return 0
    else
        echo "❌ ArgoCD is not installed"
        return 1
    fi
}

# Function to install ArgoCD
install_argocd() {
    echo ""
    echo "Installing ArgoCD..."
    
    # Create namespace
    kubectl create namespace "$ARGOCD_NAMESPACE"
    
    # Install ArgoCD
    kubectl apply -n "$ARGOCD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGOCD_NAMESPACE"
    
    echo "✅ ArgoCD installed successfully"
}

# Function to get ArgoCD admin password
get_admin_password() {
    echo ""
    echo "Retrieving ArgoCD admin password..."
    
    ARGOCD_PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-password -o jsonpath="{.data.password}" | base64 -d)
    
    echo "✅ Admin password retrieved"
}

# Function to expose ArgoCD server
expose_argocd() {
    echo ""
    echo "Exposing ArgoCD server..."
    
    # Patch service to LoadBalancer (or use port-forward)
    kubectl patch svc argocd-server -n "$ARGOCD_NAMESPACE" -p '{"spec": {"type": "LoadBalancer"}}'
    
    echo "Waiting for LoadBalancer IP..."
    sleep 10
    
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$ARGOCD_SERVER" ]; then
        ARGOCD_SERVER=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -z "$ARGOCD_SERVER" ]; then
        echo "⚠️  LoadBalancer IP not assigned yet. Use port-forward instead:"
        echo "   kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8083:443"
        ARGOCD_SERVER="localhost:8083"
    else
        echo "✅ ArgoCD server exposed at: $ARGOCD_SERVER"
    fi
}

# Function to install ArgoCD CLI
install_argocd_cli() {
    echo ""
    echo "Checking ArgoCD CLI..."
    
    if command -v argocd &> /dev/null; then
        echo "✓ ArgoCD CLI is already installed"
        return 0
    fi
    
    echo "Installing ArgoCD CLI..."
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    if [ "$OS" = "linux" ]; then
        curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
        rm /tmp/argocd
    elif [ "$OS" = "darwin" ]; then
        brew install argocd
    else
        echo "⚠️  Unsupported OS. Please install ArgoCD CLI manually:"
        echo "   https://argo-cd.readthedocs.io/en/stable/cli_installation/"
        return 1
    fi
    
    echo "✅ ArgoCD CLI installed"
}

# Function to create ArgoCD application
create_application() {
    echo ""
    echo "Creating ArgoCD application for EasyShop..."
    
    # Apply AppProject first
    if [ -f "argocd/appproject.yaml" ]; then
        echo "Applying AppProject..."
        kubectl apply -f argocd/appproject.yaml
    fi
    
    # Apply Application
    if [ -f "argocd/application.yaml" ]; then
        echo "Applying Application..."
        kubectl apply -f argocd/application.yaml
        echo "✅ ArgoCD application created"
    else
        echo "❌ argocd/application.yaml not found"
        exit 1
    fi
    
    # Apply ArgoCD Ingress
    if [ -f "argocd/argocd-ingress.yaml" ]; then
        echo "Applying ArgoCD Ingress..."
        kubectl apply -f argocd/argocd-ingress.yaml
        echo "✅ ArgoCD Ingress created"
        echo "   Access ArgoCD at: http://argocd.devopsdock.site"
    else
        echo "⚠️  argocd/argocd-ingress.yaml not found, skipping ingress setup"
    fi
}

# Function to sync application
sync_application() {
    echo ""
    echo "Syncing application..."
    
    if command -v argocd &> /dev/null; then
        # Login to ArgoCD
        echo "Logging in to ArgoCD..."
        argocd login "$ARGOCD_SERVER" --username admin --password "$ARGOCD_PASSWORD" --insecure
        
        # Sync application
        echo "Syncing $APP_NAME..."
        argocd app sync "$APP_NAME"
        
        # Wait for sync
        echo "Waiting for sync to complete..."
        argocd app wait "$APP_NAME" --timeout 300
        
        echo "✅ Application synced successfully"
    else
        echo "⚠️  ArgoCD CLI not available. Application will auto-sync based on policy."
    fi
}

# Function to display access information
display_info() {
    echo ""
    echo "=========================================="
    echo "✅ ArgoCD Setup Complete!"
    echo "=========================================="
    echo ""
    echo "ArgoCD Server: https://$ARGOCD_SERVER"
    echo "ArgoCD UI: http://argocd.devopsdock.site"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
    echo ""
    echo "Application: $APP_NAME"
    echo "Application URL: http://easyshop.devopsdock.site"
    echo "Namespace: easyshop"
    echo ""
    echo "Useful commands:"
    echo "  📊 View app status: argocd app get $APP_NAME"
    echo "  🔄 Sync app: argocd app sync $APP_NAME"
    echo "  📝 View logs: argocd app logs $APP_NAME"
    echo "  🔙 Rollback: argocd app rollback $APP_NAME"
    echo "  🌐 Open UI: argocd app open $APP_NAME"
    echo ""
    echo "Port forward (if needed):"
    echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8083:443"
    echo ""
    echo "=========================================="
}

# Main setup flow
main() {
    if ! check_argocd_installed; then
        read -p "ArgoCD is not installed. Install now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_argocd
        else
            echo "❌ ArgoCD installation cancelled"
            exit 1
        fi
    fi
    
    get_admin_password
    expose_argocd
    install_argocd_cli
    create_application
    sync_application
    display_info
}

# Run main function
main
