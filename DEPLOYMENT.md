# EasyShop Deployment Guide

Quick reference guide for deploying and managing the EasyShop e-commerce application.

## 🚀 Quick Deploy (Kind Cluster)

```bash
# 1. Setup Kind cluster (one-time)
./scripts/setup-kind-cluster.sh

# 2. Setup ArgoCD (one-time)
./scripts/argocd-setup.sh

# 3. Deploy application
./scripts/deploy.sh production

# 4. Verify deployment
./scripts/health-check.sh

# 5. Access application
open http://easyshop.local
# Or: kubectl port-forward -n easyshop svc/easyshop-service 3000:80
```

## 📋 Prerequisites

- ✅ Docker installed and running
- ✅ 8GB+ RAM available
- ✅ 20GB+ disk space
- ✅ Jenkins already configured (as mentioned)
- ✅ Docker Hub account

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   GitHub    │─────▶│   Jenkins    │─────▶│  Docker Hub │
│ Repository  │      │   Pipeline   │      │  Registry   │
└─────────────┘      └──────────────┘      └─────────────┘
      │                      │                      │
      │                      ▼                      │
      │              ┌──────────────┐               │
      └─────────────▶│   ArgoCD     │◀──────────────┘
                     │  (GitOps)    │
                     └──────────────┘
                             │
                             ▼
                     ┌──────────────┐
                     │  Kubernetes  │
                     │   Cluster    │
                     └──────────────┘
```

## 📦 Components

### Application Stack
- **Frontend/Backend:** Next.js 14
- **Database:** MongoDB (StatefulSet)
- **Ingress:** AWS ALB
- **Storage:** EBS volumes

### CI/CD Stack
- **CI:** Jenkins with shared libraries
- **CD:** ArgoCD (GitOps)
- **Registry:** Docker Hub
- **Security:** Trivy scanner

## 🔧 Setup Instructions

### 1. Jenkins Setup

```bash
# Install Jenkins (Ubuntu)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Configure Jenkins:**
1. Access Jenkins at `http://your-server:8080`
2. Install suggested plugins
3. Add credentials:
   - `docker-creds`: Docker Hub credentials
   - `github-creds`: GitHub PAT
4. Create pipeline job pointing to Jenkinsfile
5. Configure GitHub webhook

See [JENKINS.md](./JENKINS.md) for detailed setup.

### 2. ArgoCD Setup

```bash
# Automated setup
./scripts/argocd-setup.sh

# Or manual setup
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-password -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Create application
kubectl apply -f argocd/application.yaml
```

### 3. Kubernetes Cluster Setup (Kind)

**Automated Setup:**
```bash
# One command to setup everything
./scripts/setup-kind-cluster.sh
```

**What it does:**
- Creates 3-node Kind cluster
- Installs Nginx Ingress Controller
- Sets up local Docker registry
- Installs Metrics Server
- Configures /etc/hosts

**Manual Setup:**
```bash
# Create Kind cluster
kind create cluster --name easyshop-cluster --config=kind-config.yaml

# Install Nginx Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Add to /etc/hosts
echo "127.0.0.1 easyshop.local" | sudo tee -a /etc/hosts
```

See [KIND_CLUSTER_GUIDE.md](./KIND_CLUSTER_GUIDE.md) for detailed setup.

### 4. Deploy Application

```bash
# Deploy with migration
./scripts/deploy.sh production

# Deploy without migration
./scripts/deploy.sh production --skip-migration

# Check health
./scripts/health-check.sh
```

## 🔄 CI/CD Workflow

### Automated Flow

1. **Developer pushes code** → GitHub
2. **GitHub webhook triggers** → Jenkins
3. **Jenkins pipeline:**
   - Cleans workspace
   - Clones repository
   - Builds Docker images (app + migration)
   - Runs tests
   - Scans with Trivy
   - Pushes to Docker Hub
   - Updates K8s manifests with new tags
   - Commits and pushes manifest changes
4. **ArgoCD detects changes** → Auto-syncs
5. **Application deployed** → Kubernetes

### Manual Deployment

```bash
# Build and push images
docker build -t devanshpandey21/easyshop-app:v1.0.0 .
docker push devanshpandey21/easyshop-app:v1.0.0

# Update manifests
./scripts/update-image-tag.sh v1.0.0

# Commit changes
git add kubernetes/
git commit -m "Update to v1.0.0"
git push origin master

# ArgoCD will auto-sync
```

## 📊 Monitoring

### Health Checks

```bash
# Comprehensive health check
./scripts/health-check.sh

# Check specific resources
kubectl get all -n easyshop
kubectl get pods -n easyshop
kubectl get svc -n easyshop
kubectl get ingress -n easyshop
```

### Logs

```bash
# Application logs
kubectl logs -n easyshop -l app=easyshop -f

# MongoDB logs
kubectl logs -n easyshop mongodb-0 -f

# ArgoCD logs
argocd app logs easyshop -f
```

### Metrics

```bash
# Resource usage
kubectl top pods -n easyshop
kubectl top nodes

# HPA status
kubectl get hpa -n easyshop
```

## 🔙 Rollback

### Using Script

```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh 5
```

### Using ArgoCD

```bash
# View history
argocd app history easyshop

# Rollback
argocd app rollback easyshop <revision>
```

### Using kubectl

```bash
# View history
kubectl rollout history deployment/easyshop -n easyshop

# Rollback
kubectl rollout undo deployment/easyshop -n easyshop
```

## 🐛 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n easyshop
kubectl logs <pod-name> -n easyshop
kubectl get events -n easyshop --sort-by='.lastTimestamp'
```

**Image pull errors:**
```bash
# Verify image exists
docker pull devanshpandey21/easyshop-app:<tag>

# Check deployment
kubectl get deployment easyshop -n easyshop -o yaml | grep image:
```

**Database connection issues:**
```bash
# Check MongoDB
kubectl get statefulset mongodb -n easyshop
kubectl logs mongodb-0 -n easyshop

# Check PVC
kubectl get pvc -n easyshop
```

**Ingress not working:**
```bash
# Check ingress
kubectl describe ingress easyshop-ingress -n easyshop

# Check ALB controller (AWS)
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Get Help

1. Run `./scripts/health-check.sh`
2. Check [CI_CD_GUIDE.md](./CI_CD_GUIDE.md)
3. Review [JENKINS.md](./JENKINS.md)
4. Check application logs
5. Contact DevOps team

## 📚 Documentation

- [CI_CD_GUIDE.md](./CI_CD_GUIDE.md) - Complete CI/CD documentation
- [JENKINS.md](./JENKINS.md) - Jenkins setup guide
- [LOCAL_SETUP_GUIDE.md](./LOCAL_SETUP_GUIDE.md) - Local development setup
- [scripts/README.md](./scripts/README.md) - Automation scripts reference

## 🔐 Security

### Secrets Management

```bash
# View secrets (values are base64 encoded)
kubectl get secrets -n easyshop

# Update secret
kubectl create secret generic easyshop-secrets \
  --from-literal=JWT_SECRET=your-secret \
  --from-literal=NEXTAUTH_SECRET=your-secret \
  -n easyshop \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Security Scanning

```bash
# Scan with Trivy (done automatically in Jenkins)
trivy image devanshpandey21/easyshop-app:latest

# Scan filesystem
trivy fs .
```

## 🎯 Best Practices

1. ✅ Always test in development first
2. ✅ Run health checks after deployment
3. ✅ Monitor application logs
4. ✅ Keep secrets secure
5. ✅ Use semantic versioning
6. ✅ Document changes
7. ✅ Regular backups of MongoDB
8. ✅ Review security scan results

## 📞 Support

- **Documentation:** Check docs in this repository
- **Issues:** Create GitHub issue
- **DevOps Team:** Contact for cluster access
- **Emergency:** Use rollback procedures

## 🔗 Quick Links

- **Application:** http://easyshop.local or http://localhost:3000 (port-forward)
- **ArgoCD:** Port-forward to access UI
- **Jenkins:** http://your-jenkins-server:8080
- **Docker Hub:** https://hub.docker.com/r/devanshpandey21/easyshop-app

---

**Version:** 1.0  
**Last Updated:** 2024  
**Maintained By:** DevOps Team
