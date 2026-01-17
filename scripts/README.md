# EasyShop Automation Scripts

This directory contains automation scripts for deploying, managing, and monitoring the EasyShop application on Kubernetes.

## Scripts Overview

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup-kind-cluster.sh` | Setup local Kind cluster | `./setup-kind-cluster.sh` |
| `deploy.sh` | Deploy application to Kubernetes | `./deploy.sh [environment] [--skip-migration]` |
| `rollback.sh` | Rollback to previous version | `./rollback.sh [revision]` |
| `update-image-tag.sh` | Update Docker image tags | `./update-image-tag.sh <tag> [username]` |
| `health-check.sh` | Comprehensive health check | `./health-check.sh` |
| `argocd-setup.sh` | Setup ArgoCD for EasyShop | `./argocd-setup.sh` |

## Quick Start

### Initial Setup

1. **Setup Kind Cluster:**
```bash
./scripts/setup-kind-cluster.sh
```

2. **Setup ArgoCD:**
```bash
./scripts/argocd-setup.sh
```

3. **Deploy Application:**
```bash
./scripts/deploy.sh production
```

4. **Verify Health:**
```bash
./scripts/health-check.sh
```

### Daily Operations

**Check Application Health:**
```bash
./scripts/health-check.sh
```

**Update Image Version:**
```bash
./scripts/update-image-tag.sh v1.2.3
git add kubernetes/
git commit -m "Update to v1.2.3"
git push origin master
```

**Rollback if Needed:**
```bash
./scripts/rollback.sh
```

## Detailed Usage

### setup-kind-cluster.sh

Sets up a local Kind (Kubernetes in Docker) cluster for EasyShop.

**Syntax:**
```bash
./scripts/setup-kind-cluster.sh
```

**What it does:**
1. Checks prerequisites (Docker, Kind, kubectl)
2. Installs Kind and kubectl if needed
3. Creates local Docker registry (localhost:5001)
4. Creates 3-node Kind cluster:
   - 1 control-plane node
   - 2 worker nodes
   - Port mappings for ingress (80, 443)
5. Connects registry to cluster network
6. Installs Nginx Ingress Controller
7. Installs Metrics Server (for HPA)
8. Configures /etc/hosts for easyshop.local
9. Displays cluster information

**Prerequisites:**
- Docker installed and running
- 8GB+ RAM available
- 20GB+ disk space
- Linux/macOS/WSL2

**Cluster Details:**
- Name: `easyshop-cluster`
- Nodes: 3 (1 control-plane, 2 workers)
- Registry: `localhost:5001`
- Ingress: Nginx
- Domain: `easyshop.local`

**Delete Cluster:**
```bash
kind delete cluster --name easyshop-cluster
```

**Troubleshooting:**
```bash
# Check cluster
kind get clusters
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check ingress
kubectl get pods -n ingress-nginx
```

---

### deploy.sh

Deploys the EasyShop application to Kubernetes cluster.

**Syntax:**
```bash
./scripts/deploy.sh [environment] [--skip-migration]
```

**Examples:**
```bash
# Deploy to production
./scripts/deploy.sh production

# Deploy without running database migration
./scripts/deploy.sh production --skip-migration

# Deploy to development
./scripts/deploy.sh development
```

**What it does:**
1. Checks prerequisites (kubectl, cluster access)
2. Creates/verifies namespace
3. Applies Kubernetes manifests in order:
   - Namespace
   - PersistentVolume & PVC
   - ConfigMap & Secrets
   - MongoDB StatefulSet & Service
   - EasyShop Deployment & Service
   - Ingress & HPA
4. Waits for MongoDB to be ready
5. Runs database migration (unless skipped)
6. Waits for application deployment
7. Performs health checks
8. Displays access information

**Prerequisites:**
- kubectl installed and configured
- Access to Kubernetes cluster
- Proper RBAC permissions

---

### rollback.sh

Rolls back the EasyShop deployment to a previous version.

**Syntax:**
```bash
./scripts/rollback.sh [revision]
```

**Examples:**
```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh 5
```

**What it does:**
1. Shows deployment history
2. Prompts for revision (if not provided)
3. Performs rollback
4. Waits for rollback to complete
5. Verifies rollback success
6. Displays pod status

**View Revision History:**
```bash
kubectl rollout history deployment/easyshop -n easyshop
```

---

### update-image-tag.sh

Updates Docker image tags in Kubernetes manifests.

**Syntax:**
```bash
./scripts/update-image-tag.sh <image-tag> [docker-username]
```

**Examples:**
```bash
# Update to version v1.2.3
./scripts/update-image-tag.sh v1.2.3

# Update with custom Docker username
./scripts/update-image-tag.sh v1.2.3 myusername

# Update to build number
./scripts/update-image-tag.sh 42
```

**What it does:**
1. Validates input parameters
2. Updates image tag in `08-easyshop-deployment.yaml`
3. Updates image tag in `12-migration-job.yaml`
4. Creates backup files (.bak)
5. Displays modified files
6. Shows next steps for Git commit

**Files Modified:**
- `kubernetes/08-easyshop-deployment.yaml`
- `kubernetes/12-migration-job.yaml`

**Next Steps After Running:**
```bash
# Review changes
git diff kubernetes/

# Commit changes
git add kubernetes/
git commit -m "Update image tags to <tag>"

# Push to trigger ArgoCD sync
git push origin master
```

---

### health-check.sh

Performs comprehensive health check of the EasyShop deployment.

**Syntax:**
```bash
./scripts/health-check.sh
```

**What it checks:**
1. **Namespace** - Existence and status
2. **Deployments** - Ready replicas vs desired
3. **StatefulSets** - MongoDB status
4. **Pods** - Running status and health
5. **Services** - Configuration and endpoints
6. **Ingress** - ALB and routing
7. **PVCs** - Bound status
8. **HPA** - Auto-scaling configuration
9. **Endpoint** - Application accessibility
10. **Events** - Recent cluster events
11. **Resources** - CPU/Memory usage
12. **Summary** - Overall health status

**Output Example:**
```
==========================================
🏥 EasyShop Health Check
==========================================

Checking namespace...
✅ Namespace 'easyshop' exists

Checking deployments...
✅ Deployment 'easyshop': 2/2 replicas ready

Checking pods...
NAME                        READY   STATUS    RESTARTS   AGE
easyshop-7d9f8b5c4d-abc12   1/1     Running   0          5m
easyshop-7d9f8b5c4d-def34   1/1     Running   0          5m

✅ All pods are running

==========================================
📊 Health Check Summary
==========================================
✅ Overall Status: HEALTHY

Application URL: https://easyshop.devopsdock.site
Namespace: easyshop
Total Pods: 2
Running Pods: 2
==========================================
```

**Use Cases:**
- Post-deployment verification
- Troubleshooting issues
- Regular health monitoring
- Pre-maintenance checks

---

### argocd-setup.sh

Installs and configures ArgoCD for EasyShop GitOps deployment.

**Syntax:**
```bash
./scripts/argocd-setup.sh
```

**What it does:**
1. Checks if ArgoCD is already installed
2. Installs ArgoCD (if needed)
3. Waits for ArgoCD to be ready
4. Retrieves admin password
5. Exposes ArgoCD server (LoadBalancer or port-forward)
6. Installs ArgoCD CLI (if not present)
7. Creates EasyShop AppProject
8. Creates EasyShop Application
9. Performs initial sync
10. Displays access information

**Output Includes:**
- ArgoCD server URL
- Admin username and password
- Useful ArgoCD commands
- Port-forward command (if needed)

**Post-Setup:**
```bash
# Access ArgoCD UI
# Open browser to the provided URL

# Login with provided credentials
# Username: admin
# Password: <displayed in output>

# View application
argocd app get easyshop

# Sync application
argocd app sync easyshop
```

**ArgoCD CLI Commands:**
```bash
# List applications
argocd app list

# Get app details
argocd app get easyshop

# View sync status
argocd app diff easyshop

# View logs
argocd app logs easyshop -f

# Sync manually
argocd app sync easyshop

# Rollback
argocd app rollback easyshop <revision>
```

---

## Prerequisites

All scripts require:

1. **kubectl** - Kubernetes CLI tool
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

2. **Cluster Access** - Valid kubeconfig
   ```bash
   # Verify access
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Permissions** - Appropriate RBAC permissions
   - Create/update resources in `easyshop` namespace
   - Create namespace (for deploy.sh)
   - View cluster resources

## Environment Variables

Scripts use these environment variables (with defaults):

| Variable | Default | Description |
|----------|---------|-------------|
| `NAMESPACE` | `easyshop` | Kubernetes namespace |
| `DEPLOYMENT_NAME` | `easyshop` | Deployment name |
| `APP_URL` | `https://easyshop.devopsdock.site` | Application URL |
| `ARGOCD_NAMESPACE` | `argocd` | ArgoCD namespace |
| `ARGOCD_APP_NAME` | `easyshop` | ArgoCD application name |

**Override Example:**
```bash
NAMESPACE=easyshop-dev ./scripts/deploy.sh
```

## Troubleshooting

### Script Permission Denied

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or run with bash
bash scripts/deploy.sh
```

### kubectl Not Found

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Cannot Connect to Cluster

```bash
# Check kubeconfig
kubectl config view

# Check current context
kubectl config current-context

# Set context
kubectl config use-context <context-name>
```

### Insufficient Permissions

```bash
# Check your permissions
kubectl auth can-i create deployment -n easyshop
kubectl auth can-i create namespace

# Contact cluster admin for RBAC permissions
```

## Best Practices

1. **Always run health-check.sh after deployment**
2. **Review changes before running update-image-tag.sh**
3. **Test in development environment first**
4. **Keep scripts updated with infrastructure changes**
5. **Use version control for script modifications**
6. **Document any custom modifications**

## Integration with CI/CD

These scripts are designed to work with:

- **Jenkins Pipeline** - Called from Jenkinsfile stages
- **ArgoCD** - Automated GitOps deployment
- **Manual Operations** - Direct execution by operators

**Jenkins Integration Example:**
```groovy
stage('Deploy') {
    steps {
        sh './scripts/deploy.sh production'
    }
}

stage('Health Check') {
    steps {
        sh './scripts/health-check.sh'
    }
}
```

## Contributing

When modifying scripts:

1. Test thoroughly in development
2. Update this README
3. Add comments in the script
4. Follow existing code style
5. Update CI_CD_GUIDE.md if needed

## Support

For issues or questions:
1. Check script output for error messages
2. Review [CI_CD_GUIDE.md](../CI_CD_GUIDE.md)
3. Check Kubernetes logs
4. Contact DevOps team

---

**Last Updated:** 2024  
**Maintained By:** DevOps Team
