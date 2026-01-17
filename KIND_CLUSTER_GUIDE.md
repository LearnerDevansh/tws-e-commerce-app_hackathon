# Kind Cluster Setup for EasyShop

Complete guide for running EasyShop on a local Kind (Kubernetes in Docker) cluster.

## 🎯 Why Kind?

- ✅ **Local Development** - No cloud costs
- ✅ **Fast Setup** - Cluster ready in minutes
- ✅ **Isolated** - Runs in Docker containers
- ✅ **Production-like** - Real Kubernetes environment
- ✅ **CI/CD Testing** - Test pipelines locally

## 📋 Prerequisites

### Required
- **Docker** - Version 20.10+ running
- **8GB RAM** - Minimum for cluster + apps
- **20GB Disk** - For images and data
- **Linux/macOS/WSL2** - Kind works best on these

### Check Prerequisites
```bash
# Check Docker
docker --version
docker ps

# Check available resources
docker info | grep -E 'CPUs|Total Memory'
```

## 🚀 Quick Setup

### One-Command Setup
```bash
./scripts/setup-kind-cluster.sh
```

This script will:
1. Install Kind and kubectl (if needed)
2. Create a 3-node Kubernetes cluster
3. Setup local Docker registry
4. Install Nginx Ingress Controller
5. Install Metrics Server
6. Configure /etc/hosts

### Manual Setup

If you prefer manual setup:

#### 1. Install Kind
```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# macOS
brew install kind

# Windows (PowerShell as Admin)
choco install kind
```

#### 2. Install kubectl
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# macOS
brew install kubectl

# Windows
choco install kubernetes-cli
```

#### 3. Create Cluster
```bash
# Create cluster with ingress support
cat <<EOF | kind create cluster --name easyshop-cluster --config=-
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
- role: worker
- role: worker
EOF
```

#### 4. Install Nginx Ingress
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

#### 5. Install Metrics Server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for Kind
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

#### 6. Setup Hosts File
```bash
# Linux/macOS
echo "127.0.0.1 easyshop.local" | sudo tee -a /etc/hosts

# Windows (as Admin)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 easyshop.local"
```

## 🔧 Cluster Configuration

### Cluster Details

| Component | Value |
|-----------|-------|
| Cluster Name | easyshop-cluster |
| Nodes | 3 (1 control-plane, 2 workers) |
| Ingress | Nginx Ingress Controller |
| Storage | Local hostPath |
| Registry | localhost:5001 (optional) |
| Domain | easyshop.local |

### Port Mappings

| Service | Port | Access |
|---------|------|--------|
| HTTP | 80 | http://easyshop.local |
| HTTPS | 443 | https://easyshop.local |
| NodePort | 30000 | http://localhost:30000 |

## 📦 Deploy EasyShop

### Using Deployment Script
```bash
# Deploy application
./scripts/deploy.sh production

# Check health
./scripts/health-check.sh
```

### Manual Deployment
```bash
# Apply all manifests
kubectl apply -f kubernetes/

# Wait for pods
kubectl wait --for=condition=ready pod -l app=easyshop -n easyshop --timeout=300s

# Check status
kubectl get all -n easyshop
```

## 🌐 Access Application

### Option 1: Via Ingress (Recommended)
```bash
# Access via hostname
open http://easyshop.local

# Or with curl
curl http://easyshop.local
```

### Option 2: Via Port Forward
```bash
# Forward service port
kubectl port-forward -n easyshop svc/easyshop-service 3000:80

# Access application
open http://localhost:3000
```

### Option 3: Via NodePort
```bash
# Get NodePort
kubectl get svc -n easyshop easyshop-service

# Access via NodePort (if configured)
open http://localhost:30000
```

## 🔍 Cluster Management

### View Cluster Info
```bash
# Cluster info
kubectl cluster-info
kind get clusters

# Node status
kubectl get nodes

# All resources
kubectl get all --all-namespaces
```

### View Logs
```bash
# Application logs
kubectl logs -n easyshop -l app=easyshop -f

# Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# All pod logs in namespace
kubectl logs -n easyshop --all-containers=true -f
```

### Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n easyshop

# All pods
kubectl top pods --all-namespaces
```

## 🐛 Troubleshooting

### Cluster Issues

**Cluster won't start:**
```bash
# Check Docker
docker ps

# Check Docker resources
docker info

# Delete and recreate
kind delete cluster --name easyshop-cluster
./scripts/setup-kind-cluster.sh
```

**Nodes not ready:**
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system
```

### Ingress Issues

**Ingress not working:**
```bash
# Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check Ingress resource
kubectl get ingress -n easyshop
kubectl describe ingress easyshop-ingress -n easyshop

# Test with port-forward instead
kubectl port-forward -n easyshop svc/easyshop-service 3000:80
```

**Can't access easyshop.local:**
```bash
# Check /etc/hosts
cat /etc/hosts | grep easyshop

# Add if missing
echo "127.0.0.1 easyshop.local" | sudo tee -a /etc/hosts

# Test DNS resolution
ping easyshop.local

# Try with curl
curl -v http://easyshop.local
```

### Storage Issues

**PVC not binding:**
```bash
# Check PV and PVC
kubectl get pv
kubectl get pvc -n easyshop

# Describe PVC
kubectl describe pvc mongodb-pvc -n easyshop

# Check storage class
kubectl get storageclass
```

**Fix:**
```bash
# Delete and recreate PVC
kubectl delete pvc mongodb-pvc -n easyshop
kubectl apply -f kubernetes/03-mongodb-pvc.yaml

# Or use dynamic provisioning
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Application Issues

**Pods not starting:**
```bash
# Check pod status
kubectl get pods -n easyshop

# Describe pod
kubectl describe pod <pod-name> -n easyshop

# Check logs
kubectl logs <pod-name> -n easyshop

# Check events
kubectl get events -n easyshop --sort-by='.lastTimestamp'
```

**ImagePullBackOff:**
```bash
# Check image name
kubectl get deployment easyshop -n easyshop -o yaml | grep image:

# Pull image manually
docker pull devanshpandey21/easyshop-app:latest

# Load image into Kind
kind load docker-image devanshpandey21/easyshop-app:latest --name easyshop-cluster
```

## 🔄 CI/CD with Kind

### Jenkins Integration

Your Jenkins is already configured. The pipeline will:
1. Build Docker images
2. Push to Docker Hub
3. Update Kubernetes manifests
4. ArgoCD syncs to Kind cluster

### Load Images Directly

For faster local development:
```bash
# Build image
docker build -t easyshop-app:local .

# Load into Kind
kind load docker-image easyshop-app:local --name easyshop-cluster

# Update deployment
kubectl set image deployment/easyshop easyshop=easyshop-app:local -n easyshop
```

### Local Registry (Optional)

Use local registry to avoid Docker Hub:
```bash
# Tag image for local registry
docker tag easyshop-app:latest localhost:5001/easyshop-app:latest

# Push to local registry
docker push localhost:5001/easyshop-app:latest

# Update deployment to use local registry
kubectl set image deployment/easyshop easyshop=localhost:5001/easyshop-app:latest -n easyshop
```

## 🧹 Cleanup

### Delete Application
```bash
# Delete namespace (removes all resources)
kubectl delete namespace easyshop

# Or delete specific resources
kubectl delete -f kubernetes/
```

### Delete Cluster
```bash
# Delete Kind cluster
kind delete cluster --name easyshop-cluster

# Verify deletion
kind get clusters
```

### Delete Registry
```bash
# Stop and remove registry
docker stop kind-registry
docker rm kind-registry
```

### Complete Cleanup
```bash
# Delete everything
kind delete cluster --name easyshop-cluster
docker stop kind-registry && docker rm kind-registry
docker system prune -a
```

## 💡 Tips and Best Practices

### Performance

1. **Allocate enough resources to Docker:**
   - CPU: 4+ cores
   - RAM: 8GB+ 
   - Disk: 20GB+

2. **Use local registry for faster image loading**

3. **Load images directly into Kind:**
   ```bash
   kind load docker-image <image> --name easyshop-cluster
   ```

### Development Workflow

1. **Make code changes**
2. **Build image locally**
3. **Load into Kind cluster**
4. **Test changes**
5. **Push to Git when ready**

### Debugging

1. **Use kubectl port-forward for direct access**
2. **Check logs frequently**
3. **Use kubectl describe for detailed info**
4. **Monitor resource usage**

## 📚 Additional Resources

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Nginx Ingress for Kind](https://kind.sigs.k8s.io/docs/user/ingress/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

## 🆘 Getting Help

1. Run health check: `./scripts/health-check.sh`
2. Check cluster: `kubectl cluster-info`
3. View logs: `kubectl logs -n easyshop -l app=easyshop`
4. Check events: `kubectl get events -n easyshop`
5. Consult [QUICKSTART.md](./QUICKSTART.md)

---

**Happy Local Kubernetes Development! 🚀**
