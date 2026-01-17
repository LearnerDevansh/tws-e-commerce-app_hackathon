# EasyShop CI/CD Quick Start (Kind Cluster)

Get your CI/CD pipeline up and running locally with Kind!

## ✅ Pre-Flight Checklist

- [ ] Docker installed and running
- [ ] Jenkins already configured (as mentioned)
- [ ] GitHub repository access
- [ ] 8GB+ RAM available
- [ ] 20GB+ disk space

## 🚀 10-Minute Local Setup

### Step 1: Setup Kind Cluster (5 minutes)

```bash
# Create Kind cluster with ingress and local registry
./scripts/setup-kind-cluster.sh
```

**What this does:**
- ✅ Installs Kind and kubectl (if needed)
- ✅ Creates 3-node cluster (1 control-plane, 2 workers)
- ✅ Sets up local Docker registry
- ✅ Installs Nginx Ingress Controller
- ✅ Installs Metrics Server
- ✅ Configures /etc/hosts for easyshop.local

**Verify cluster:**
```bash
kubectl cluster-info
kubectl get nodes
```

### Step 1.5: Configure Jenkins (Already Done ✅)

Since Jenkins is already configured on your device, just ensure:
- [ ] Docker Hub credentials configured (`docker-creds`)
- [ ] GitHub credentials configured (`github-creds`)
- [ ] Pipeline job created pointing to Jenkinsfile
- [ ] GitHub webhook configured (optional for local)

### Step 2: Setup ArgoCD (5 minutes)

```bash
# Automated setup
./scripts/argocd-setup.sh
```

**Or manual:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
```

### Step 3: Deploy Application (2 minutes)

```bash
# Deploy everything
./scripts/deploy.sh production

# Verify
./scripts/health-check.sh
```

### Step 4: Verify (1 minute)

```bash
# Check pods
kubectl get pods -n easyshop

# Check application (via ingress)
curl http://easyshop.local

# Or open in browser
open http://easyshop.local

# Or use port-forward
kubectl port-forward -n easyshop svc/easyshop-service 3000:80
# Then open http://localhost:3000
```

## 🎯 Test the Pipeline

### Trigger a Build

```bash
# Make a change
echo "# Test change" >> README.md

# Commit and push
git add README.md
git commit -m "Test CI/CD pipeline"
git push origin master
```

**What happens:**
1. ✅ GitHub webhook triggers Jenkins
2. ✅ Jenkins builds Docker images
3. ✅ Trivy scans for vulnerabilities
4. ✅ Images pushed to Docker Hub
5. ✅ Kubernetes manifests updated
6. ✅ ArgoCD syncs changes
7. ✅ Application deployed

### Monitor the Build

**Jenkins:**
- Open Jenkins UI
- Click on your pipeline job
- Watch console output

**ArgoCD:**
```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser
open https://localhost:8080

# Or via CLI
argocd app get easyshop
argocd app sync easyshop --watch
```

**Kubernetes:**
```bash
# Watch pods
kubectl get pods -n easyshop -w

# Watch deployment
kubectl rollout status deployment/easyshop -n easyshop
```

## 📋 Daily Operations

### Check Application Health
```bash
./scripts/health-check.sh
```

### View Logs
```bash
# Application logs
kubectl logs -n easyshop -l app=easyshop -f

# ArgoCD logs
argocd app logs easyshop -f
```

### Update Application
```bash
# Update image tag
./scripts/update-image-tag.sh v1.2.3

# Commit and push
git add kubernetes/
git commit -m "Update to v1.2.3"
git push origin master

# ArgoCD auto-syncs in ~3 minutes
```

### Rollback
```bash
# Rollback to previous version
./scripts/rollback.sh

# Or specific revision
./scripts/rollback.sh 5
```

## 🐛 Quick Troubleshooting

### Jenkins Build Fails
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins
```

### ArgoCD Not Syncing
```bash
# Check app status
argocd app get easyshop

# Force sync
argocd app sync easyshop --force

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Pods Not Starting
```bash
# Describe pod
kubectl describe pod <pod-name> -n easyshop

# Check logs
kubectl logs <pod-name> -n easyshop

# Check events
kubectl get events -n easyshop --sort-by='.lastTimestamp'
```

### Application Not Accessible
```bash
# Check ingress
kubectl get ingress -n easyshop
kubectl describe ingress easyshop-ingress -n easyshop

# Check Nginx Ingress Controller
kubectl get pods -n ingress-nginx

# Check /etc/hosts
cat /etc/hosts | grep easyshop

# Test with port-forward
kubectl port-forward -n easyshop svc/easyshop-service 3000:80
# Then access http://localhost:3000
```

## 📚 Next Steps

1. **Read Full Documentation:**
   - [CI_CD_GUIDE.md](./CI_CD_GUIDE.md) - Complete CI/CD guide
   - [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment reference
   - [JENKINS.md](./JENKINS.md) - Jenkins details
   - [scripts/README.md](./scripts/README.md) - Scripts reference

2. **Configure Monitoring:**
   - Setup Prometheus/Grafana
   - Configure alerts
   - Setup log aggregation

3. **Enhance Security:**
   - Rotate secrets
   - Enable RBAC
   - Configure network policies
   - Regular security scans

4. **Optimize:**
   - Configure HPA properly
   - Optimize resource limits
   - Setup backup strategy
   - Configure disaster recovery

## 🎓 Learning Resources

- **Jenkins:** https://www.jenkins.io/doc/
- **ArgoCD:** https://argo-cd.readthedocs.io/
- **Kubernetes:** https://kubernetes.io/docs/
- **GitOps:** https://www.gitops.tech/

## 💡 Pro Tips

1. **Use health-check.sh regularly** - Catch issues early
2. **Monitor ArgoCD UI** - Visual feedback is helpful
3. **Keep manifests in Git** - Single source of truth
4. **Test in dev first** - Avoid production issues
5. **Document changes** - Help your future self

## 🆘 Get Help

1. Run `./scripts/health-check.sh`
2. Check logs: `kubectl logs -n easyshop -l app=easyshop`
3. Review documentation in this repo
4. Check ArgoCD UI for sync status
5. Contact DevOps team

## ✨ Success Indicators

You're all set when you see:

- ✅ Jenkins builds successfully
- ✅ ArgoCD shows "Synced" and "Healthy"
- ✅ All pods are "Running"
- ✅ Application accessible at http://easyshop.local or http://localhost:3000
- ✅ Health check shows "HEALTHY"

---

**Congratulations! Your CI/CD pipeline is ready! 🎉**

For detailed information, see [CI_CD_GUIDE.md](./CI_CD_GUIDE.md)
