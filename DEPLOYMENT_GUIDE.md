# GearUp Kubernetes Deployment Guide (Using Neon Database)

## 🎯 Overview

Your application uses:
- ✅ **Neon PostgreSQL** (Cloud - Already exists, no deployment needed)
- ✅ **Redis** (Deployed in Kubernetes for caching)
- ✅ **Spring Boot Backend** (Deployed in Kubernetes)
- ✅ **Next.js Frontend** (Deployed in Kubernetes)

## 📋 Prerequisites

### 1. Install Required Tools

Open PowerShell as **Administrator**:

```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Docker Desktop, kubectl, and Minikube
choco install docker-desktop kubernetes-cli minikube -y
```

**Restart PowerShell** after installation.

### 2. Create Docker Hub Account
- Go to https://hub.docker.com
- Sign up for free account
- Remember your username

## 🚀 Deployment Steps

### Step 1: Start Kubernetes Cluster

```powershell
# Start Minikube
minikube start --cpus=4 --memory=4096 --driver=docker

# Enable ingress addon
minikube addons enable ingress

# Verify it's running
minikube status
```

### Step 2: Build and Push Docker Images

```powershell
# Navigate to project root
cd c:\Users\adeep\OneDrive\Documents\Desktop\EAD-Group

# Login to Docker Hub
docker login

# Build backend image
cd gear-up-be
docker build -t your-dockerhub-username/gearup-backend:latest .

# Build frontend image
cd ../gear-up-fe
docker build -f Dockerfile.k8s -t your-dockerhub-username/gearup-frontend:latest .

# Push images to Docker Hub
docker push your-dockerhub-username/gearup-backend:latest
docker push your-dockerhub-username/gearup-frontend:latest

cd ..
```

**Note**: Replace `your-dockerhub-username` with your actual Docker Hub username.

### Step 3: Update Deployment Files

Update the image names in:
- `k8s/backend-deployment.yaml` (line 26)
- `k8s/frontend-deployment.yaml` (line 19)

Replace `your-dockerhub-username` with your Docker Hub username.

### Step 4: Deploy to Kubernetes

```powershell
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create secrets (database credentials already configured from your .env)
kubectl apply -f k8s/secrets.yaml

# Create configmaps
kubectl apply -f k8s/configmap.yaml

# Deploy Redis cache
kubectl apply -f k8s/redis-pvc.yaml
kubectl apply -f k8s/redis-deployment.yaml

# Wait for Redis to be ready
kubectl wait --for=condition=ready pod -l app=redis -n gearup --timeout=120s

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n gearup --timeout=180s

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml
```

### Step 5: Verify Deployment

```powershell
# Check all resources
kubectl get all -n gearup

# Check pods status
kubectl get pods -n gearup

# Check services
kubectl get svc -n gearup

# View backend logs
kubectl logs -f deployment/backend -n gearup

# View frontend logs
kubectl logs -f deployment/frontend -n gearup
```

### Step 6: Access Your Application

```powershell
# Get the frontend service URL
minikube service frontend-service -n gearup --url

# Or get the LoadBalancer details
kubectl get svc frontend-service -n gearup
```

Open the URL in your browser!

## 🔍 For Assignment Submission (5 Marks)

### 1. ConfigMaps Screenshot
```powershell
kubectl get configmaps -n gearup
kubectl describe configmap backend-config -n gearup
```
Shows application configuration management ✅

### 2. Secrets Screenshot
```powershell
kubectl get secrets -n gearup
kubectl describe secret gearup-secrets -n gearup
```
Shows sensitive data management (passwords, JWT secret) ✅

### 3. Services Screenshot
```powershell
kubectl get svc -n gearup
kubectl describe svc backend-service -n gearup
kubectl describe svc frontend-service -n gearup
kubectl describe svc redis-service -n gearup
```
Shows networking between components ✅

### 4. All Resources Screenshot
```powershell
kubectl get all -n gearup -o wide
```
Shows complete deployment ✅

### 5. Pod Details Screenshot
```powershell
kubectl get pods -n gearup
kubectl describe pod <backend-pod-name> -n gearup
```
Shows pod configuration with ConfigMaps and Secrets ✅

### 6. Working Application
- Screenshot of frontend in browser
- Screenshot of backend API (Swagger): http://<external-ip>/swagger-ui/index.html
- Screenshot of GraphQL playground: http://<external-ip>/graphql

## 🛠️ Automated Deployment (Alternative)

Instead of manual steps, use the automated script:

```powershell
# Run deployment script
.\deploy.ps1 -DockerUsername "your-dockerhub-username"

# Skip build if images already exist
.\deploy.ps1 -DockerUsername "your-dockerhub-username" -SkipBuild
```

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │   Frontend   │      │   Backend    │                    │
│  │  (Next.js)   │─────▶│ (Spring Boot)│                    │
│  │  Port: 3000  │      │  Port: 8080  │                    │
│  └──────────────┘      └──────┬───────┘                    │
│         │                     │                             │
│         │              ┌──────┴────────┐                    │
│         │              │               │                    │
│         │         ┌────▼─────┐  ┌─────▼─────┐             │
│         │         │  Redis   │  │   Neon    │             │
│         │         │  Cache   │  │ PostgreSQL│ (External)  │
│         │         │ (K8s)    │  │  (Cloud)  │             │
│         │         └──────────┘  └───────────┘             │
│         │                                                   │
│  ┌──────▼──────────────────────────────────────────┐      │
│  │              Ingress Controller                   │      │
│  │     Routes traffic to Frontend/Backend           │      │
│  └──────────────────────────────────────────────────┘      │
│                           │                                 │
└───────────────────────────┼─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  LoadBalancer  │
                    │  External IP   │
                    └────────────────┘
```

## 🔧 Troubleshooting

### Backend Not Starting?
```powershell
# Check logs
kubectl logs deployment/backend -n gearup

# Common issues:
# 1. Database connection - Check Neon database is accessible
# 2. Image pull error - Make sure images are pushed to Docker Hub
# 3. Port conflicts - Check if port 8080 is available
```

### Frontend Not Connecting to Backend?
```powershell
# Check if backend service is running
kubectl get svc backend-service -n gearup

# Check frontend environment variables
kubectl describe configmap frontend-config -n gearup

# Check frontend logs
kubectl logs deployment/frontend -n gearup
```

### Redis Connection Issues?
```powershell
# Check Redis pod
kubectl get pods -n gearup | findstr redis
kubectl logs deployment/redis -n gearup

# Test Redis connection from backend pod
kubectl exec -it deployment/backend -n gearup -- /bin/sh
# Inside pod: redis-cli -h redis-service ping
```

### Image Pull Errors?
```powershell
# Make sure you're logged in to Docker Hub
docker login

# Verify images exist
docker images | findstr gearup

# Push again if needed
docker push your-username/gearup-backend:latest
docker push your-username/gearup-frontend:latest
```

## 🧹 Cleanup

```powershell
# Delete everything
kubectl delete namespace gearup

# Or delete individually
kubectl delete -f k8s/ingress.yaml
kubectl delete -f k8s/frontend-deployment.yaml
kubectl delete -f k8s/backend-deployment.yaml
kubectl delete -f k8s/redis-deployment.yaml
kubectl delete -f k8s/redis-pvc.yaml
kubectl delete -f k8s/configmap.yaml
kubectl delete -f k8s/secrets.yaml
kubectl delete -f k8s/namespace.yaml

# Stop Minikube
minikube stop

# Delete Minikube (complete reset)
minikube delete
```

## 🌐 Deploy to GKE (Production - Optional)

### 1. Setup Google Cloud
```powershell
# Install Google Cloud SDK
choco install gcloudsdk -y

# Login and create project
gcloud auth login
gcloud projects create gearup-ead-2025
gcloud config set project gearup-ead-2025

# Enable Kubernetes Engine
gcloud services enable container.googleapis.com
```

### 2. Create Cluster
```powershell
# Create GKE cluster (uses free credits)
gcloud container clusters create gearup-cluster `
  --num-nodes=2 `
  --machine-type=e2-medium `
  --zone=us-central1-a

# Get credentials
gcloud container clusters get-credentials gearup-cluster --zone=us-central1-a
```

### 3. Deploy (Same Commands!)
```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/redis-pvc.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

### 4. Get External IP
```powershell
kubectl get svc frontend-service -n gearup
# Wait for EXTERNAL-IP (2-3 minutes)
```

Access at: `http://<EXTERNAL-IP>`

## 📝 Key Components Explained

### ConfigMaps (1 mark)
- Stores non-sensitive configuration
- Environment variables for backend/frontend
- Can be updated without rebuilding images
- Located in: `k8s/configmap.yaml`

### Secrets (1 mark)
- Stores sensitive data (passwords, API keys)
- Base64 encoded
- Database credentials from Neon
- JWT secret for authentication
- Email credentials for notifications
- Located in: `k8s/secrets.yaml`

### Services (1 mark)
- **ClusterIP**: Internal communication (backend, redis)
- **LoadBalancer**: External access (frontend)
- Enables service discovery
- Load balancing across pods
- Located in: Each deployment file

### Deployments (2 marks)
- **Backend**: 2 replicas for high availability
- **Frontend**: 2 replicas for load distribution
- **Redis**: 1 replica for caching
- Health checks and resource limits
- Located in: `k8s/*-deployment.yaml`

## ✅ Success Criteria

You have successfully deployed when:
1. ✅ All pods are in "Running" state
2. ✅ Frontend is accessible via browser
3. ✅ Backend API responds (check /actuator/health)
4. ✅ GraphQL endpoint works
5. ✅ Application connects to Neon database
6. ✅ Redis caching is working

## 🎓 Assignment Checklist

- [ ] Install all prerequisites
- [ ] Start Minikube cluster
- [ ] Build and push Docker images
- [ ] Deploy all Kubernetes resources
- [ ] Take screenshot of `kubectl get all -n gearup`
- [ ] Take screenshot of ConfigMaps
- [ ] Take screenshot of Secrets
- [ ] Take screenshot of Services
- [ ] Take screenshot of working application
- [ ] Test all functionality
- [ ] Document any issues and solutions

Good luck with your deployment! 🚀

## 🆘 Need Help?

Common commands:
```powershell
# View logs
kubectl logs -f deployment/backend -n gearup
kubectl logs -f deployment/frontend -n gearup

# Restart deployment
kubectl rollout restart deployment/backend -n gearup
kubectl rollout restart deployment/frontend -n gearup

# Get shell access
kubectl exec -it deployment/backend -n gearup -- /bin/bash

# Check events
kubectl get events -n gearup --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward svc/backend-service 8080:8080 -n gearup
kubectl port-forward svc/frontend-service 3000:80 -n gearup
```
