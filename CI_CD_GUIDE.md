# CI/CD Pipeline Guide for EasyShop

This guide covers the complete CI/CD setup for the EasyShop e-commerce application using Jenkins and ArgoCD for GitOps deployment.

## Architecture Overview

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│   GitHub    │─────▶│   Jenkins    │─────▶│  Docker Hub │─────▶│   ArgoCD     │
│ Repository  │      │   Pipeline   │      │  Registry   │      │  (GitOps)    │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────────┘
      │                      │                                            │
      │                      │                                            ▼
      │                      │                                    ┌──────────────┐
      │                      └───────────────────────────────────▶│  Kubernetes  │
      └────────────────────────────────────────────────────────────▶   Cluster    │
                    Update Manifests (Git Push)                   └──────────────┘
```

## CI/CD Flow

1. **Developer pushes code** to GitHub repository
2. **Jenkins webhook triggers** the pipeline automatically
3. **Jenkins builds** Docker images for app and migration
4. **Security scanning** with Trivy
5. **Push images** to Docker Hub registry
6. **Update Kubernetes manifests** with new image tags
7. **ArgoCD detects changes** and syncs to cluster
8. **Application deployed** to Kubernetes

## Jenkins Pipeline

**Features:**
- Shared library integration for reusable functions
- Parallel builds for app and migration images
- Trivy security scanning
- Automatic Kubernetes manifest updates
- ArgoCD sync triggering
- Deployment verification
- Comprehensive logging

**Setup:**

1. **Follow the [JENKINS.md](./JENKINS.md) guide** for initial Jenkins installation

2. **Configure Jenkins Credentials:**
   - `docker-creds`: Docker Hub username and password
   - `github-creds`: GitHub personal access token (with repo access)
   - `argocd-server`: ArgoCD server URL (optional)

3. **Install Required Plugins:**
   - Docker Pipeline
   - Git Plugin
   - Pipeline Utility Steps
   - Credentials Binding

4. **Configure Webhook:**
   - Go to GitHub repository → Settings → Webhooks
   - Add webhook: `http://your-jenkins-url:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Push events

5. **Create Pipeline Job:**
   - New Item → Pipeline
   - Configure SCM: Git
   - Repository URL: Your GitHub repo
   - Branch: `*/master`
   - Script Path: `Jenkinsfile`

**Pipeline Stages:**

1. **Cleanup Workspace** - Clean previous build artifacts
2. **Clone Repository** - Fetch latest code from GitHub
3. **Build Docker Images** - Build app and migration images in parallel
4. **Run Unit Tests** - Execute test suite
5. **Security Scan with Trivy** - Scan for vulnerabilities
6. **Push Docker Images** - Push to Docker Hub in parallel
7. **Update Kubernetes Manifests** - Update image tags in K8s files
8. **Trigger ArgoCD Sync** - Notify ArgoCD to sync (optional)
9. **Verify Deployment** - Check deployment status
10. **Deployment Summary** - Display build information

**Environment Variables:**

```groovy
DOCKER_IMAGE_NAME = 'devanshpandey21/easyshop-app'
DOCKER_MIGRATION_IMAGE_NAME = 'devanshpandey21/easyshop-migration'
DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
K8S_NAMESPACE = "easyshop"
ARGOCD_APP_NAME = "easyshop"
```

## Automation Scripts

The `scripts/` directory contains helper scripts for deployment automation:

### 1. deploy.sh

**Purpose:** Deploy EasyShop application to Kubernetes cluster

**Usage:**
```bash
# Deploy to production
./scripts/deploy.sh production

# Deploy without running migration
./scripts/deploy.sh production --skip-migration
```

**What it does:**
- Checks prerequisites (kubectl, cluster access)
- Creates namespace if needed
- Applies all Kubernetes manifests in correct order
- Runs database migration job
- Waits for deployments to be ready
- Performs health checks
- Displays access information

### 2. rollback.sh

**Purpose:** Rollback EasyShop deployment to previous version

**Usage:**
```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh 5
```

**What it does:**
- Shows deployment history
- Rolls back to specified or previous revision
- Waits for rollback to complete
- Verifies rollback success
- Displays pod status

### 3. update-image-tag.sh

**Purpose:** Update Docker image tags in Kubernetes manifests

**Usage:**
```bash
# Update to specific tag
./scripts/update-image-tag.sh v1.2.3

# Update with custom Docker username
./scripts/update-image-tag.sh v1.2.3 myusername
```

**What it does:**
- Updates image tags in deployment and migration manifests
- Creates backup files
- Shows modified files
- Provides next steps for Git commit

### 4. health-check.sh

**Purpose:** Comprehensive health check of EasyShop deployment

**Usage:**
```bash
./scripts/health-check.sh
```

**What it does:**
- Checks namespace existence
- Verifies deployments and statefulsets
- Lists pod status
- Checks services and ingress
- Verifies PVCs and HPA
- Tests application endpoint
- Shows recent events
- Displays resource usage
- Generates health summary

### 5. argocd-setup.sh

**Purpose:** Install and configure ArgoCD for EasyShop

**Usage:**
```bash
./scripts/argocd-setup.sh
```

**What it does:**
- Checks if ArgoCD is installed
- Installs ArgoCD if needed
- Retrieves admin password
- Exposes ArgoCD server
- Installs ArgoCD CLI
- Creates EasyShop application
- Syncs application
- Displays access information

## ArgoCD GitOps Deployment

ArgoCD provides declarative, GitOps continuous delivery for Kubernetes. It monitors your Git repository and automatically syncs changes to your cluster.

### Quick Setup

Use the automated setup script:

```bash
./scripts/argocd-setup.sh
```

This script will:
- Install ArgoCD (if not present)
- Configure access
- Create the EasyShop application
- Perform initial sync

### Manual Installation

If you prefer manual setup:

1. **Install ArgoCD:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. **Wait for ArgoCD to be ready:**
```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

3. **Access ArgoCD UI:**
```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-password -o jsonpath="{.data.password}" | base64 -d
```

4. **Install ArgoCD CLI (optional):**
```bash
# Linux
curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 /tmp/argocd /usr/local/bin/argocd

# macOS
brew install argocd
```

5. **Login via CLI:**
```bash
argocd login localhost:8080
argocd account update-password
```

### Deploy EasyShop Application

1. **Create the AppProject (optional):**
```bash
kubectl apply -f argocd/appproject.yaml
```

2. **Create the Application:**
```bash
kubectl apply -f argocd/application.yaml
```

3. **Verify deployment:**
```bash
# Via CLI
argocd app get easyshop
argocd app sync easyshop

# Via kubectl
kubectl get application easyshop -n argocd
```

### ArgoCD Configuration

The EasyShop ArgoCD application is configured with:

**Auto-Sync Policy:**
- ✅ Automatically syncs when Git manifests change
- ✅ Self-healing enabled (corrects manual changes)
- ✅ Pruning enabled (removes deleted resources)
- ✅ Creates namespace automatically

**Sync Options:**
- `CreateNamespace=true` - Auto-create target namespace
- `PrunePropagationPolicy=foreground` - Proper resource cleanup
- `PruneLast=true` - Delete resources after new ones are healthy
- `ApplyOutOfSyncOnly=true` - Only sync changed resources

**Retry Policy:**
- Limit: 5 attempts
- Backoff: 5s initial, 2x factor, 3m max

**Ignored Differences:**
- Deployment replicas (managed by HPA)
- StatefulSet replicas
- Secret data (for security)

### ArgoCD Features

| Feature | Status | Description |
|---------|--------|-------------|
| Auto-Sync | ✅ Enabled | Automatically deploys Git changes |
| Self-Heal | ✅ Enabled | Reverts manual cluster changes |
| Pruning | ✅ Enabled | Removes deleted resources |
| Revision History | ✅ 10 revisions | Enables rollback |
| Health Assessment | ✅ Enabled | Monitors app health |
| Sync Waves | ✅ Configured | Ordered deployment |

## Docker Images

Two images are built:

1. **Main Application**: `easyshop-app`
   - Next.js application
   - Multi-stage build for optimization
   - Production-ready

2. **Migration**: `easyshop-migration`
   - Database migration scripts
   - Runs as Kubernetes Job

## Security Scanning

### Trivy Integration

Both pipelines include Trivy scanning:

**Jenkins:**
- Scans Docker images before push
- Fails build on HIGH/CRITICAL vulnerabilities
- Generates HTML reports

**GitHub Actions:**
- Scans filesystem and Docker images
- Uploads results to GitHub Security tab
- SARIF format for integration

### Best Practices

1. **Image Tagging:**
   - Use Git commit SHA for traceability
   - Tag with branch name
   - Always tag `latest` for main branch

2. **Secrets Management:**
   - Never commit secrets to Git
   - Use Kubernetes Secrets
   - Rotate credentials regularly

3. **Resource Limits:**
   - Set CPU/memory requests and limits
   - Configure HPA for auto-scaling
   - Monitor resource usage

## Monitoring and Observability

### Application Health

ArgoCD monitors:
- Deployment status
- Pod health
- Service availability
- Ingress configuration

### Logs

Access logs via:
```bash
# Application logs
kubectl logs -n easyshop -l app=easyshop -f

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

### Metrics

Prometheus metrics available at:
- Application: `/metrics` endpoint
- ArgoCD: Built-in metrics
- Kubernetes: Node and pod metrics

## Rollback Procedures

### ArgoCD Rollback

```bash
# List history
argocd app history easyshop

# Rollback to specific revision
argocd app rollback easyshop <REVISION>
```

### Manual Rollback

```bash
# Rollback deployment
kubectl rollout undo deployment/easyshop -n easyshop

# Check rollout status
kubectl rollout status deployment/easyshop -n easyshop
```

## Quick Start Guide

### First Time Setup

1. **Setup Jenkins:**
```bash
# Follow JENKINS.md for installation
# Configure credentials and webhook
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

### Daily Workflow

1. **Make code changes** and push to GitHub
2. **Jenkins automatically:**
   - Builds Docker images
   - Runs tests and security scans
   - Pushes images to Docker Hub
   - Updates Kubernetes manifests
3. **ArgoCD automatically:**
   - Detects manifest changes
   - Syncs to Kubernetes cluster
   - Monitors application health
4. **Verify deployment:**
```bash
./scripts/health-check.sh
```

## Troubleshooting

### Pipeline Failures

**Jenkins Build Fails:**

1. Check Jenkins console output
2. Review build logs:
```bash
# Jenkins logs
sudo journalctl -u jenkins -f

# Or check Jenkins UI
```

3. Common issues:
   - Docker daemon not running
   - Insufficient permissions
   - Network connectivity issues
   - Missing credentials

**Fix:**
```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Check Docker
sudo systemctl status docker

# Verify credentials in Jenkins UI
```

### ArgoCD Sync Issues

**Application Out of Sync:**

```bash
# Check application status
argocd app get easyshop

# View detailed sync status
argocd app diff easyshop

# View sync logs
argocd app logs easyshop --follow

# Force sync
argocd app sync easyshop --force

# Refresh app (re-read Git)
argocd app refresh easyshop
```

**Sync Fails:**

1. Check ArgoCD application events:
```bash
kubectl describe application easyshop -n argocd
```

2. Check ArgoCD controller logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

3. Common issues:
   - Invalid Kubernetes manifests
   - Resource conflicts
   - Insufficient RBAC permissions
   - Git repository access issues

### Deployment Issues

**Pods Not Starting:**

```bash
# Check pod status
kubectl get pods -n easyshop

# Describe problematic pod
kubectl describe pod <pod-name> -n easyshop

# Check pod logs
kubectl logs <pod-name> -n easyshop --tail=100

# Check events
kubectl get events -n easyshop --sort-by='.lastTimestamp'
```

**Common pod issues:**
- ImagePullBackOff: Image doesn't exist or registry auth failed
- CrashLoopBackOff: Application crashes on startup
- Pending: Insufficient resources or PVC issues

### Image Pull Errors

**ImagePullBackOff:**

```bash
# Verify image exists in Docker Hub
docker pull devanshpandey21/easyshop-app:<tag>

# Check if image tag is correct
kubectl get deployment easyshop -n easyshop -o yaml | grep image:

# Describe pod for detailed error
kubectl describe pod <pod-name> -n easyshop
```

**Fix:**
```bash
# Update image tag
./scripts/update-image-tag.sh <correct-tag>

# Commit and push
git add kubernetes/
git commit -m "Fix image tag"
git push origin master

# ArgoCD will auto-sync
```

### Database Connection Issues

**MongoDB Not Ready:**

```bash
# Check MongoDB status
kubectl get statefulset mongodb -n easyshop
kubectl get pods -n easyshop -l app=mongodb

# Check MongoDB logs
kubectl logs -n easyshop mongodb-0

# Check PVC
kubectl get pvc -n easyshop
```

**Fix:**
```bash
# Restart MongoDB
kubectl rollout restart statefulset/mongodb -n easyshop

# Wait for ready
kubectl rollout status statefulset/mongodb -n easyshop
```

### Ingress Issues

**Application Not Accessible:**

```bash
# Check ingress
kubectl get ingress -n easyshop
kubectl describe ingress easyshop-ingress -n easyshop

# Check ALB controller logs (if using AWS)
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify DNS
nslookup easyshop.devopsdock.site
```

### Health Check Failures

Run comprehensive health check:

```bash
./scripts/health-check.sh
```

This will identify:
- Pod issues
- Service misconfigurations
- Ingress problems
- Resource constraints
- Recent error events

## Rollback Procedures

### Using ArgoCD

**Rollback via CLI:**
```bash
# List application history
argocd app history easyshop

# Rollback to specific revision
argocd app rollback easyshop <REVISION>

# Example: Rollback to revision 5
argocd app rollback easyshop 5
```

**Rollback via UI:**
1. Open ArgoCD UI
2. Navigate to easyshop application
3. Click "History and Rollback"
4. Select desired revision
5. Click "Rollback"

### Using Kubernetes

**Rollback deployment:**
```bash
# Use the rollback script
./scripts/rollback.sh

# Or manually
kubectl rollout undo deployment/easyshop -n easyshop

# Rollback to specific revision
kubectl rollout undo deployment/easyshop -n easyshop --to-revision=5

# Check rollout status
kubectl rollout status deployment/easyshop -n easyshop
```

### Using Git

**Revert to previous commit:**
```bash
# Find the commit to revert to
git log --oneline

# Revert to specific commit
git revert <commit-hash>

# Push changes
git push origin master

# ArgoCD will auto-sync the revert
```

## Monitoring and Observability

### Application Monitoring

**Check Application Health:**
```bash
# Run health check script
./scripts/health-check.sh

# Check via ArgoCD
argocd app get easyshop

# Check via kubectl
kubectl get all -n easyshop
```

**View Application Logs:**
```bash
# All easyshop pods
kubectl logs -n easyshop -l app=easyshop -f

# Specific pod
kubectl logs -n easyshop <pod-name> -f

# Previous pod instance
kubectl logs -n easyshop <pod-name> -f --previous
```

**View ArgoCD Logs:**
```bash
# Application logs via ArgoCD
argocd app logs easyshop --follow

# ArgoCD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

### Metrics and Performance

**Resource Usage:**
```bash
# Pod resource usage
kubectl top pods -n easyshop

# Node resource usage
kubectl top nodes

# HPA status
kubectl get hpa -n easyshop
```

**Application Metrics:**
- Access Prometheus (if configured)
- View Grafana dashboards
- Check application /metrics endpoint

### Alerts and Notifications

Configure alerts for:
- Build failures (Jenkins)
- Deployment failures (ArgoCD)
- Pod crashes
- High resource usage
- Application errors

## Best Practices

### Git Workflow

1. **Branch Strategy:**
   - `master` - Production deployments
   - `develop` - Development environment
   - `feature/*` - Feature branches

2. **Commit Messages:**
   - Use conventional commits
   - Include ticket/issue numbers
   - Be descriptive

3. **Pull Requests:**
   - Require code reviews
   - Run CI checks before merge
   - Keep PRs small and focused

### Docker Images

1. **Tagging Strategy:**
   - Use semantic versioning (v1.2.3)
   - Tag with Git commit SHA
   - Always tag `latest` for main branch
   - Use build numbers for traceability

2. **Image Optimization:**
   - Use multi-stage builds
   - Minimize layer count
   - Remove unnecessary files
   - Use .dockerignore

3. **Security:**
   - Scan images with Trivy
   - Use official base images
   - Keep images updated
   - Don't include secrets

### Kubernetes Manifests

1. **Resource Management:**
   - Always set resource requests/limits
   - Configure HPA for auto-scaling
   - Use PodDisruptionBudgets

2. **Configuration:**
   - Use ConfigMaps for config
   - Use Secrets for sensitive data
   - Never hardcode values
   - Use environment-specific configs

3. **Health Checks:**
   - Configure liveness probes
   - Configure readiness probes
   - Configure startup probes
   - Set appropriate timeouts

### ArgoCD

1. **Application Management:**
   - Use AppProjects for multi-tenancy
   - Enable auto-sync for automation
   - Enable self-heal for consistency
   - Configure sync waves for ordering

2. **Security:**
   - Use RBAC for access control
   - Rotate credentials regularly
   - Enable audit logging
   - Use SSO for authentication

## CI/CD Metrics

Track these key metrics:

| Metric | Target | Description |
|--------|--------|-------------|
| Build Success Rate | >95% | Percentage of successful builds |
| Build Duration | <10 min | Average time for complete build |
| Deployment Frequency | Daily | How often code is deployed |
| Lead Time | <1 hour | Time from commit to production |
| MTTR | <30 min | Mean time to recovery |
| Change Failure Rate | <5% | Percentage of failed deployments |

**View Metrics:**
```bash
# Jenkins build history
# Check Jenkins UI dashboard

# ArgoCD sync history
argocd app history easyshop

# Deployment frequency
kubectl rollout history deployment/easyshop -n easyshop
```

## Security Considerations

### Secrets Management

1. **Never commit secrets to Git**
2. Use Kubernetes Secrets
3. Consider external secret managers (AWS Secrets Manager, Vault)
4. Rotate secrets regularly
5. Use RBAC to restrict secret access

### Image Security

1. **Scan images with Trivy**
2. Fix HIGH/CRITICAL vulnerabilities
3. Use minimal base images
4. Keep dependencies updated
5. Sign images for verification

### Cluster Security

1. **Enable RBAC**
2. Use Network Policies
3. Enable Pod Security Standards
4. Regular security audits
5. Keep Kubernetes updated

## Useful Commands Reference

### Jenkins
```bash
# Restart Jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f

# Check status
sudo systemctl status jenkins
```

### ArgoCD
```bash
# Login
argocd login <server> --username admin

# List applications
argocd app list

# Get app details
argocd app get easyshop

# Sync app
argocd app sync easyshop

# View logs
argocd app logs easyshop -f

# Rollback
argocd app rollback easyshop <revision>
```

### Kubernetes
```bash
# Get resources
kubectl get all -n easyshop

# Describe resource
kubectl describe deployment easyshop -n easyshop

# View logs
kubectl logs -n easyshop -l app=easyshop -f

# Execute command in pod
kubectl exec -it <pod-name> -n easyshop -- /bin/sh

# Port forward
kubectl port-forward -n easyshop svc/easyshop-service 3000:80

# Scale deployment
kubectl scale deployment easyshop -n easyshop --replicas=3

# Restart deployment
kubectl rollout restart deployment/easyshop -n easyshop
```

### Docker
```bash
# Build image
docker build -t easyshop-app:latest .

# Push image
docker push devanshpandey21/easyshop-app:latest

# Pull image
docker pull devanshpandey21/easyshop-app:latest

# List images
docker images

# Remove image
docker rmi <image-id>
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitOps Principles](https://www.gitops.tech/)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)

## Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly:**
   - Review failed builds
   - Check resource usage
   - Review security scan results

2. **Monthly:**
   - Update dependencies
   - Rotate credentials
   - Review and optimize costs
   - Update documentation

3. **Quarterly:**
   - Kubernetes version upgrades
   - ArgoCD version upgrades
   - Security audit
   - Disaster recovery testing

### Getting Help

1. Check this documentation
2. Review troubleshooting section
3. Check application logs
4. Review ArgoCD/Jenkins logs
5. Consult team documentation
6. Contact DevOps team

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Maintained By:** DevOps Team
