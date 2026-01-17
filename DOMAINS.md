# Domain Configuration for EasyShop

## 🌐 Configured Domains

| Service | Domain | Port | Access |
|---------|--------|------|--------|
| **EasyShop App** | easyshop.devopsdock.site | 80 | http://easyshop.devopsdock.site |
| **ArgoCD UI** | argocd.devopsdock.site | 80 | http://argocd.devopsdock.site |

## 📝 /etc/hosts Configuration

The setup script automatically adds these entries to `/etc/hosts`:

```bash
127.0.0.1 easyshop.devopsdock.site
127.0.0.1 argocd.devopsdock.site
```

### Manual Configuration

If you need to add them manually:

**Linux/macOS:**
```bash
echo "127.0.0.1 easyshop.devopsdock.site" | sudo tee -a /etc/hosts
echo "127.0.0.1 argocd.devopsdock.site" | sudo tee -a /etc/hosts
```

**Windows (PowerShell as Admin):**
```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 easyshop.devopsdock.site"
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 argocd.devopsdock.site"
```

### Verify Configuration

```bash
# Check /etc/hosts
cat /etc/hosts | grep devopsdock

# Test DNS resolution
ping easyshop.devopsdock.site
ping argocd.devopsdock.site

# Test with curl
curl http://easyshop.devopsdock.site
curl http://argocd.devopsdock.site
```

## 🔧 Ingress Configuration

### EasyShop Ingress

Located at: `kubernetes/10-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: easyshop-ingress
  namespace: easyshop
spec:
  ingressClassName: nginx
  rules:
  - host: easyshop.devopsdock.site
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: easyshop-service
            port:
              number: 80
```

### ArgoCD Ingress

Located at: `argocd/argocd-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.devopsdock.site
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: https
```

## 🚀 Access Methods

### Option 1: Via Domain (Recommended)

After running the setup script:

```bash
# Access EasyShop
open http://easyshop.devopsdock.site

# Access ArgoCD
open http://argocd.devopsdock.site
```

### Option 2: Via Port Forward

If ingress is not working:

```bash
# EasyShop
kubectl port-forward -n easyshop svc/easyshop-service 3000:80
open http://localhost:3000

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443
open https://localhost:8080
```

### Option 3: Via NodePort

If you configured NodePort services:

```bash
# Get NodePort
kubectl get svc -n easyshop
kubectl get svc -n argocd

# Access via NodePort
open http://localhost:<nodeport>
```

## 🐛 Troubleshooting

### Domain Not Resolving

**Check /etc/hosts:**
```bash
cat /etc/hosts | grep devopsdock
```

**Expected output:**
```
127.0.0.1 easyshop.devopsdock.site
127.0.0.1 argocd.devopsdock.site
```

**If missing, add manually:**
```bash
echo "127.0.0.1 easyshop.devopsdock.site" | sudo tee -a /etc/hosts
echo "127.0.0.1 argocd.devopsdock.site" | sudo tee -a /etc/hosts
```

### Ingress Not Working

**Check Nginx Ingress Controller:**
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

**Check Ingress Resources:**
```bash
kubectl get ingress -n easyshop
kubectl get ingress -n argocd
kubectl describe ingress easyshop-ingress -n easyshop
kubectl describe ingress argocd-server-ingress -n argocd
```

**Verify Ingress Controller is Running:**
```bash
kubectl get svc -n ingress-nginx
```

### Connection Refused

**Check if services are running:**
```bash
# EasyShop
kubectl get pods -n easyshop
kubectl get svc -n easyshop

# ArgoCD
kubectl get pods -n argocd
kubectl get svc -n argocd
```

**Test with curl:**
```bash
# Test EasyShop
curl -v http://easyshop.devopsdock.site

# Test ArgoCD
curl -v http://argocd.devopsdock.site
```

### Browser Shows "This site can't be reached"

1. **Verify /etc/hosts:**
   ```bash
   cat /etc/hosts | grep devopsdock
   ```

2. **Ping the domain:**
   ```bash
   ping easyshop.devopsdock.site
   ```
   Should resolve to 127.0.0.1

3. **Check if port 80 is available:**
   ```bash
   sudo lsof -i :80
   ```

4. **Restart browser** or clear DNS cache:
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   
   # Linux
   sudo systemd-resolve --flush-caches
   
   # Windows
   ipconfig /flushdns
   ```

## 🔐 SSL/TLS (Optional)

For local development, we're using HTTP. For production or if you want HTTPS:

### Option 1: Self-Signed Certificate

```bash
# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.devopsdock.site"

# Create secret
kubectl create secret tls devopsdock-tls \
  --cert=tls.crt --key=tls.key -n easyshop

kubectl create secret tls devopsdock-tls \
  --cert=tls.crt --key=tls.key -n argocd

# Update ingress to use TLS
```

### Option 2: Let's Encrypt with cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
# Configure ingress with cert-manager annotations
```

## 📚 Related Documentation

- [QUICKSTART.md](./QUICKSTART.md) - Quick setup guide
- [KIND_CLUSTER_GUIDE.md](./KIND_CLUSTER_GUIDE.md) - Kind cluster details
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment guide

## 💡 Tips

1. **Always check /etc/hosts first** when domains don't resolve
2. **Use curl -v** for detailed connection debugging
3. **Check ingress controller logs** for routing issues
4. **Port-forward is your friend** when ingress has issues
5. **Clear browser cache** if you see stale content

---

**Need Help?** Run `./scripts/health-check.sh` for diagnostics.
