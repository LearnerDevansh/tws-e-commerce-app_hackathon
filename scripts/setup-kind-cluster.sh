#!/bin/bash

# Setup Kind Cluster for EasyShop
# Usage: ./setup-kind-cluster.sh

set -e

CLUSTER_NAME="easyshop-cluster"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

echo "=========================================="
echo "🚀 Setting up Kind Cluster for EasyShop"
echo "=========================================="

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v kind &> /dev/null; then
        echo "❌ Kind is not installed"
        echo "Installing Kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed"
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/kubectl
    fi
    
    echo "✅ All prerequisites met"
}

# Function to create local registry
create_registry() {
    echo ""
    echo "Setting up local Docker registry..."
    
    # Check if registry already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
        echo "Registry already exists"
        if ! docker ps --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
            echo "Starting existing registry..."
            docker start ${REGISTRY_NAME}
        fi
    else
        echo "Creating local registry..."
        docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" registry:2
    fi
    
    echo "✅ Local registry running at localhost:${REGISTRY_PORT}"
}

# Function to create Kind cluster
create_cluster() {
    echo ""
    echo "Creating Kind cluster..."
    
    # Check if cluster already exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo "⚠️  Cluster '${CLUSTER_NAME}' already exists"
        read -p "Delete and recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Deleting existing cluster..."
            kind delete cluster --name ${CLUSTER_NAME}
        else
            echo "Using existing cluster"
            return 0
        fi
    fi
    
    # Create cluster with ingress support
    cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
  - containerPort: 31246
    hostPort: 31246
    protocol: TCP
  - containerPort: 32533
    hostPort: 32533
    protocol: TCP
- role: worker
- role: worker
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:5000"]
EOF
    
    echo "✅ Kind cluster created"
}

# Function to connect registry to cluster
connect_registry() {
    echo ""
    echo "Connecting registry to cluster network..."
    
    # Connect registry to cluster network if not already connected
    if ! docker network inspect kind | grep -q ${REGISTRY_NAME}; then
        docker network connect "kind" "${REGISTRY_NAME}" 2>/dev/null || true
    fi
    
    # Document the local registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
    
    echo "✅ Registry connected to cluster"
}

# Function to install Nginx Ingress
install_ingress() {
    echo ""
    echo "Installing Nginx Ingress Controller..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    echo "Waiting for Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s
    
    echo "✅ Nginx Ingress Controller installed"
}

# Function to install metrics server
install_metrics_server() {
    echo ""
    echo "Installing Metrics Server..."
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for Kind
    kubectl patch -n kube-system deployment metrics-server --type=json \
      -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
    
    echo "✅ Metrics Server installed"
}

# Function to setup hosts file
setup_hosts() {
    echo ""
    echo "Setting up /etc/hosts..."
    
    # Check if entries already exist
    if grep -q "easyshop.devopsdock.site" /etc/hosts; then
        echo "✓ easyshop.devopsdock.site already in /etc/hosts"
    else
        echo "Adding easyshop.devopsdock.site to /etc/hosts..."
        echo "127.0.0.1 easyshop.devopsdock.site" | sudo tee -a /etc/hosts
        echo "✅ Added easyshop.devopsdock.site to /etc/hosts"
    fi
    
    if grep -q "argocd.devopsdock.site" /etc/hosts; then
        echo "✓ argocd.devopsdock.site already in /etc/hosts"
    else
        echo "Adding argocd.devopsdock.site to /etc/hosts..."
        echo "127.0.0.1 argocd.devopsdock.site" | sudo tee -a /etc/hosts
        echo "✅ Added argocd.devopsdock.site to /etc/hosts"
    fi
}

# Function to display cluster info
display_info() {
    echo ""
    echo "=========================================="
    echo "✅ Kind Cluster Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Cluster Name: ${CLUSTER_NAME}"
    echo "Registry: localhost:${REGISTRY_PORT}"
    echo "Nodes:"
    kubectl get nodes
    echo ""
    echo "Useful commands:"
    echo "  📊 View cluster: kubectl cluster-info"
    echo "  📦 View nodes: kubectl get nodes"
    echo "  🔍 View all: kubectl get all --all-namespaces"
    echo "  🗑️  Delete cluster: kind delete cluster --name ${CLUSTER_NAME}"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy application: ./scripts/deploy.sh production"
    echo "  2. Access at: http://easyshop.devopsdock.site"
    echo "  3. Or port-forward: kubectl port-forward -n easyshop svc/easyshop-service 3000:80"
    echo ""
    echo "=========================================="
}

# Main setup flow
main() {
    check_prerequisites
    create_registry
    create_cluster
    connect_registry
    install_ingress
    install_metrics_server
    setup_hosts
    display_info
}

# Run main function
main
