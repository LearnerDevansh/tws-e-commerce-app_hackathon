# EasyShop Local Development Guide

## ✅ Current Status
Your application is now running locally with Docker!

## 🚀 Quick Commands

### Start the application
```bash
docker compose up -d
```

### Stop the application
```bash
docker compose down
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs easyshop -f
docker logs easyshop-mongodb -f
```

### Rebuild after code changes
```bash
docker compose up -d --build
```

### Check running containers
```bash
docker ps
```

## 🔗 Access Points
- **Application:** http://localhost:3000
- **MongoDB:** localhost:27017

## 📝 Next Steps for Practice

### 1. Local Development (Current Stage ✅)
- [x] Docker Desktop installed
- [x] Application running in containers
- [x] MongoDB with data migration

### 2. Jenkins CI/CD Setup (Next)
Since you have Jenkins installed, let's set it up:

#### A. Start Jenkins
```bash
# If Jenkins is not running
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  jenkins/jenkins:lts
```

#### B. Access Jenkins
- URL: http://localhost:8080
- Get initial password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### C. Install Required Plugins
- Docker Pipeline
- GitHub Integration
- Pipeline Utility Steps

#### D. Create Jenkins Pipeline
1. Create new Pipeline job
2. Point to your Jenkinsfile
3. Configure Docker Hub credentials

### 3. Practice Scenarios

#### Scenario 1: Make a Code Change
1. Edit any file in `src/`
2. Rebuild: `docker compose up -d --build`
3. Check changes at http://localhost:3000

#### Scenario 2: Database Operations
```bash
# Connect to MongoDB
docker exec -it easyshop-mongodb mongosh

# Inside mongosh
use easyshop
db.products.find()
db.users.find()
```

#### Scenario 3: Debugging
```bash
# Enter the app container
docker exec -it easyshop sh

# Check environment variables
env | grep MONGODB

# Check files
ls -la
```

### 4. Jenkins Pipeline Practice

#### Test the Jenkinsfile locally
The Jenkinsfile has these stages:
1. Cleanup Workspace
2. Clone Repository
3. Build Docker Images (parallel)
4. Run Unit Tests
5. Security Scan with Trivy
6. Push to Docker Hub
7. Update K8s Manifests

#### Install Trivy for security scanning
```bash
# Windows (using Chocolatey)
choco install trivy

# Or download from: https://github.com/aquasecurity/trivy/releases
```

### 5. Kubernetes Practice (Without Cloud)

#### Install Minikube for local K8s
```bash
# Windows
choco install minikube

# Start minikube
minikube start

# Apply your manifests
kubectl apply -f kubernetes/
```

### 6. Monitoring Setup (Local)

#### Run Prometheus + Grafana locally
```bash
# Create docker-compose.monitoring.yml
docker compose -f docker-compose.monitoring.yml up -d
```

## 🛠️ Troubleshooting

### Port already in use
```bash
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process
taskkill /PID <PID> /F
```

### Container won't start
```bash
# Check logs
docker logs easyshop

# Remove and recreate
docker compose down
docker compose up -d --build
```

### MongoDB connection issues
```bash
# Check MongoDB is healthy
docker inspect easyshop-mongodb | findstr Health

# Restart MongoDB
docker restart easyshop-mongodb
```

## 📚 Learning Path

1. **Week 1: Local Development**
   - Understand Docker Compose
   - Make code changes and rebuild
   - Database operations

2. **Week 2: CI/CD**
   - Set up Jenkins locally
   - Create pipeline jobs
   - Integrate with GitHub webhooks

3. **Week 3: Kubernetes**
   - Install Minikube
   - Deploy to local K8s
   - Practice with kubectl

4. **Week 4: Monitoring**
   - Set up Prometheus/Grafana
   - Create dashboards
   - Set up alerts

## 🎯 Practice Exercises

### Exercise 1: Add a New Feature
1. Create a new API endpoint in `src/app/api/`
2. Test locally
3. Commit and push
4. Watch Jenkins build

### Exercise 2: Database Migration
1. Modify `scripts/migrate-data.ts`
2. Add new sample data
3. Rebuild migration container
4. Verify data in MongoDB

### Exercise 3: Environment Variables
1. Add new env var to `.env.local`
2. Use it in your code
3. Rebuild and test

### Exercise 4: Multi-stage Build Optimization
1. Analyze current Dockerfile
2. Reduce image size
3. Compare before/after

## 📖 Resources
- [Docker Docs](https://docs.docker.com/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Next.js Docs](https://nextjs.org/docs)

---

**Current Setup:**
- ✅ Docker Desktop
- ✅ Application running
- ✅ MongoDB with data
- 🔄 Jenkins (ready to configure)
- ⏳ Kubernetes (Minikube - optional)
- ⏳ Monitoring (next step)
