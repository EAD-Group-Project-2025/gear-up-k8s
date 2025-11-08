# Kubernetes Deployment Guide for GearUp Application

This guide will help you deploy the GearUp application (Frontend, Backend, PostgreSQL, Redis) to Kubernetes.

## Prerequisites

### 1. Install Required Tools

#### Windows (PowerShell):
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Docker Desktop
choco install docker-desktop -y

# Install kubectl
choco install kubernetes-cli -y

# Install Minikube
choco install minikube -y
```

### 2. Enable Kubernetes in Docker Desktop (Alternative to Minikube)
- Open Docker Desktop
- Go to Settings > Kubernetes
- Check "Enable Kubernetes"
- Click "Apply & Restart"

## Step 1: Start Minikube (if using Minikube)

```powershell
# Start Minikube
minikube start --driver=docker --cpus=4 --memory=4096

# Enable ingress addon
minikube addons enable ingress

# Check status
minikube status
```

## Step 2: Configure Secrets Using .env File

### Setup .env file:
```powershell
# Navigate to k8s folder
cd k8s

# Copy the example file
Copy-Item .env.example .env

# Edit .env file with your actual values
notepad .env
```

### Required values in .env:
- `SPRING_DATASOURCE_URL`: Your PostgreSQL database URL
- `SPRING_DATASOURCE_USERNAME`: Database username
- `SPRING_DATASOURCE_PASSWORD`: Database password
- `JWT_SECRET`: Generate using: `openssl rand -base64 64` (or use PowerShell: `[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString() + (New-Guid).ToString()))`)
- `MAIL_USERNAME`: Your Gmail address
- `MAIL_PASSWORD`: Your Gmail App Password (not regular password!)

To get Gmail App Password:
1. Go to Google Account Settings
2. Security > 2-Step Verification
3. App Passwords
4. Generate new app password

### Create Kubernetes Secrets from .env:
```powershell
# Run the script to create secrets from .env file
.\create-secrets-from-env.ps1
```

**Important:** The `.env` file is already in `.gitignore` to prevent committing secrets to git

### Update Docker Image Names
In the following files, replace `your-dockerhub-username` with your actual Docker Hub username:
- `k8s/backend-deployment.yaml`
- `k8s/frontend-deployment.yaml`

## Step 3: Build and Push Docker Images

### Backend:
```powershell
cd gear-up-be

# Build the image
docker build -t your-dockerhub-username/gearup-backend:latest .

# Login to Docker Hub
docker login

# Push to Docker Hub
docker push your-dockerhub-username/gearup-backend:latest
```

### Frontend:
```powershell
cd ../gear-up-fe

# Build the image (using the new Dockerfile.k8s)
docker build -f Dockerfile.k8s -t your-dockerhub-username/gearup-frontend:latest .

# Push to Docker Hub
docker push your-dockerhub-username/gearup-frontend:latest
```

## Step 4: Deploy to Kubernetes

```powershell
cd ../k8s

# Create namespace
kubectl apply -f namespace.yaml

# Create secrets from .env file
.\create-secrets-from-env.ps1

# Create configmaps
kubectl apply -f configmap.yaml

# Create persistent volume claims
kubectl apply -f postgres-pvc.yaml
kubectl apply -f redis-pvc.yaml

# Deploy databases
kubectl apply -f postgres-deployment.yaml
kubectl apply -f redis-deployment.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n gearup --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n gearup --timeout=120s

# Deploy backend
kubectl apply -f backend-deployment.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n gearup --timeout=120s

# Deploy frontend
kubectl apply -f frontend-deployment.yaml

# Deploy ingress
kubectl apply -f ingress.yaml
```

## Step 5: Access Your Application

### Using Minikube:
```powershell
# Get the Minikube IP
minikube ip

# Add to hosts file (run as Administrator)
# Add this line to C:\Windows\System32\drivers\etc\hosts
# <minikube-ip> gearup.local

# Get the service URL
minikube service frontend-service -n gearup --url
```

### Using Docker Desktop Kubernetes:
```powershell
# Get LoadBalancer IP/Port
kubectl get svc frontend-service -n gearup

# Access at: http://localhost:<NodePort>
```

## Step 6: Verify Deployment

```powershell
# Check all resources
kubectl get all -n gearup

# Check pods status
kubectl get pods -n gearup

# Check services
kubectl get svc -n gearup

# View pod logs
kubectl logs -f deployment/backend -n gearup
kubectl logs -f deployment/frontend -n gearup

# Check ConfigMaps
kubectl get configmaps -n gearup
kubectl describe configmap backend-config -n gearup

# Check Secrets
kubectl get secrets -n gearup
kubectl describe secret gearup-secrets -n gearup
```

## Step 7: Test the Application

1. **Frontend**: http://gearup.local (or the LoadBalancer IP)
2. **Backend API**: http://gearup.local/api
3. **GraphQL**: http://gearup.local/graphql
4. **Swagger**: http://gearup.local/swagger-ui/index.html

## Troubleshooting

### Check Pod Status:
```powershell
kubectl get pods -n gearup
kubectl describe pod <pod-name> -n gearup
kubectl logs <pod-name> -n gearup
```

### Check Events:
```powershell
kubectl get events -n gearup --sort-by='.lastTimestamp'
```

### Restart a Deployment:
```powershell
kubectl rollout restart deployment/backend -n gearup
kubectl rollout restart deployment/frontend -n gearup
```

### Access Pod Shell:
```powershell
kubectl exec -it <pod-name> -n gearup -- /bin/sh
```

### Check Database Connection:
```powershell
# Connect to PostgreSQL pod
kubectl exec -it <postgres-pod-name> -n gearup -- psql -U gearup_user -d gearup_db
```

## Scaling

```powershell
# Scale backend
kubectl scale deployment/backend -n gearup --replicas=3

# Scale frontend
kubectl scale deployment/frontend -n gearup --replicas=3
```

## Cleanup

```powershell
# Delete all resources
kubectl delete namespace gearup

# Or delete individually
kubectl delete -f ingress.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-deployment.yaml
kubectl delete -f redis-deployment.yaml
kubectl delete -f postgres-deployment.yaml
kubectl delete -f postgres-pvc.yaml
kubectl delete -f redis-pvc.yaml
kubectl delete -f configmap.yaml
kubectl delete -f secrets.yaml
kubectl delete -f namespace.yaml
```

## For Assignment Submission

### Take Screenshots of:
1. **All running pods**: `kubectl get pods -n gearup`
2. **All services**: `kubectl get svc -n gearup`
3. **ConfigMap contents**: `kubectl describe configmap backend-config -n gearup`
4. **Secret (without showing sensitive data)**: `kubectl get secrets -n gearup`
5. **Ingress**: `kubectl get ingress -n gearup`
6. **Working application** in browser

### Show Commands:
```powershell
# Show all resources at once
kubectl get all -n gearup

# Show ConfigMaps usage
kubectl get configmaps -n gearup -o yaml

# Show Secrets usage (keys only, not values)
kubectl get secrets gearup-secrets -n gearup -o yaml

# Show Service definitions
kubectl get svc -n gearup -o yaml
```

## Deploy to GKE (Google Kubernetes Engine) - For Production

### 1. Setup GKE:
```powershell
# Install gcloud CLI
choco install gcloudsdk -y

# Login to Google Cloud
gcloud auth login

# Create cluster
gcloud container clusters create gearup-cluster --num-nodes=3 --zone=us-central1-a

# Get credentials
gcloud container clusters get-credentials gearup-cluster --zone=us-central1-a
```

### 2. Deploy (same commands as above)
```powershell
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
# ... rest of the deployment commands
```

### 3. Get External IP:
```powershell
kubectl get svc frontend-service -n gearup
# Wait for EXTERNAL-IP to be assigned
```

## Security Notes

### HTTPS/SSL Certificate
**Current deployment uses HTTP (not HTTPS)** for simplicity and demo purposes.

**For production, you should add HTTPS by:**
1. Obtaining a domain name
2. Using one of these SSL options:
   - **Google-Managed SSL Certificates** (easiest for GKE)
   - **Let's Encrypt with cert-manager** (free, auto-renewing)
   - **Commercial SSL certificate**

**Setup files for HTTPS are included:**
- `ssl-certificate.yaml` - Google-managed certificate
- `cert-issuer.yaml` - Let's Encrypt issuer
- `ingress-tls.yaml` - HTTPS-enabled ingress
- `HTTPS-SETUP.md` - Detailed setup guide

**Note:** SSL certificates require a domain name. HTTP is acceptable for:
- Development/testing environments
- Internal networks
- Demo/POC projects
- Educational purposes

## Notes

- **Resource Limits**: Adjust CPU/Memory in deployment files based on your cluster capacity
- **Storage Class**: Change `storageClassName` in PVC files if needed (default is `standard`)
- **Image Pull Policy**: Default is `Always`, change to `IfNotPresent` for faster local testing
- **Environment Variables**: All configuration uses ConfigMaps and Secrets as required

Good luck with your deployment! 🚀
#   g e a r - u p - k 8 s 
 
 