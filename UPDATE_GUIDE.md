# Quick Guide: Update GKE Deployment with New Changes

## 🚀 Quick Update (Automated)

### Option 1: Update Both Backend and Frontend
```powershell
cd c:\Users\adeep\OneDrive\Documents\Desktop\EAD-Group
.\update-gke-deployment.ps1 -DockerUsername "your-dockerhub-username"
```

### Option 2: Update Backend Only
```powershell
.\update-gke-deployment.ps1 -DockerUsername "your-dockerhub-username" -BackendOnly
```

### Option 3: Update Frontend Only
```powershell
.\update-gke-deployment.ps1 -DockerUsername "your-dockerhub-username" -FrontendOnly
```

### Option 4: Update with Custom Tag
```powershell
.\update-gke-deployment.ps1 -DockerUsername "your-dockerhub-username" -Tag "v1.1.0"
```

## 📋 Manual Update Steps

### Step 1: Build New Docker Images

```powershell
# Make sure you're logged into Docker Hub
docker login

# Build and push backend
cd gear-up-be
docker build -t your-dockerhub-username/gearup-backend:latest .
docker push your-dockerhub-username/gearup-backend:latest
cd ..

# Build and push frontend
cd gear-up-fe
docker build -f Dockerfile.k8s -t your-dockerhub-username/gearup-frontend:latest .
docker push your-dockerhub-username/gearup-frontend:latest
cd ..
```

### Step 2: Restart Kubernetes Deployments

```powershell
# This will pull the new images and restart pods
kubectl rollout restart deployment/backend -n gearup
kubectl rollout restart deployment/frontend -n gearup
```

### Step 3: Monitor the Update

```powershell
# Watch the rollout status
kubectl rollout status deployment/backend -n gearup
kubectl rollout status deployment/frontend -n gearup

# Check pod status
kubectl get pods -n gearup -w
```

## 🔍 Verification Commands

### Check if pods are running
```powershell
kubectl get pods -n gearup
```

### View backend logs
```powershell
kubectl logs -f deployment/backend -n gearup
```

### View frontend logs
```powershell
kubectl logs -f deployment/frontend -n gearup
```

### Check all resources
```powershell
kubectl get all -n gearup
```

### Get application URL
```powershell
kubectl get svc frontend-service -n gearup
# Look for EXTERNAL-IP column
```

## 🐛 Troubleshooting

### If pods are not starting:
```powershell
# Check pod events
kubectl describe pod <pod-name> -n gearup

# Check logs
kubectl logs <pod-name> -n gearup

# Check if image was pulled
kubectl get events -n gearup --sort-by='.lastTimestamp'
```

### If image pull fails:
```powershell
# Make sure image exists on Docker Hub
docker pull your-dockerhub-username/gearup-backend:latest
docker pull your-dockerhub-username/gearup-frontend:latest

# If using private repo, create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  -n gearup
```

### Rollback if something goes wrong:
```powershell
# Rollback backend to previous version
kubectl rollout undo deployment/backend -n gearup

# Rollback frontend to previous version
kubectl rollout undo deployment/frontend -n gearup

# Check rollout history
kubectl rollout history deployment/backend -n gearup
kubectl rollout history deployment/frontend -n gearup
```

## 📊 Health Check

After deployment, verify:

1. **Backend Health**:
   - Get external IP: `kubectl get svc backend-service -n gearup`
   - Visit: `http://<backend-ip>:8080/actuator/health`
   - Should return: `{"status":"UP"}`

2. **Frontend Accessibility**:
   - Get external IP: `kubectl get svc frontend-service -n gearup`
   - Visit: `http://<frontend-ip>`
   - Application should load

3. **Database Connection**:
   - Backend logs should show successful Neon database connection
   - No error messages about database connectivity

## 🎯 What the Update Does

1. **Builds new Docker images** with your latest code changes
2. **Pushes images** to Docker Hub registry
3. **Triggers Kubernetes rollout** which:
   - Creates new pods with updated images
   - Gradually replaces old pods (zero-downtime deployment)
   - Keeps old pods running until new ones are healthy
4. **Verifies** the deployment completed successfully

## ⚡ Zero-Downtime Deployment

Kubernetes automatically:
- ✅ Creates new pods before terminating old ones
- ✅ Ensures new pods are healthy before routing traffic
- ✅ Maintains minimum number of replicas during update
- ✅ Allows rollback if new version fails health checks

## 📝 Important Notes

1. **Always commit your changes to Git before deploying**
2. **Tag your Docker images** for version tracking (e.g., v1.0.0, v1.1.0)
3. **Test locally** before deploying to production
4. **Monitor logs** during and after deployment
5. **Keep track of rollout history** for easy rollback

## 🔄 Update Frequency

- **Development**: Update as needed for testing
- **Staging**: Update after feature completion
- **Production**: Update during maintenance windows or off-peak hours

## 💡 Pro Tips

1. **Use tags for versioning**:
   ```powershell
   docker build -t username/gearup-backend:v1.2.0 .
   docker build -t username/gearup-backend:latest .
   ```

2. **Monitor during deployment**:
   ```powershell
   # In one terminal
   kubectl get pods -n gearup -w
   
   # In another terminal
   kubectl logs -f deployment/backend -n gearup
   ```

3. **Set image pull policy** to ensure latest image:
   In your deployment YAML, ensure:
   ```yaml
   imagePullPolicy: Always
   ```

4. **Use health checks** to ensure smooth rollout:
   Already configured in your deployment files! ✅

## 🆘 Getting Help

If you encounter issues:

1. **Check deployment status**:
   ```powershell
   kubectl get deployments -n gearup
   kubectl describe deployment backend -n gearup
   ```

2. **View recent events**:
   ```powershell
   kubectl get events -n gearup --sort-by='.lastTimestamp' | Select-Object -Last 20
   ```

3. **Connect to pod for debugging**:
   ```powershell
   kubectl exec -it deployment/backend -n gearup -- /bin/bash
   ```

## ✅ Deployment Checklist

Before deploying:
- [ ] All code committed to Git
- [ ] Tests passing locally
- [ ] Docker Hub credentials configured
- [ ] kubectl connected to correct cluster
- [ ] Backup of current deployment (if critical)

After deploying:
- [ ] All pods in Running state
- [ ] Application accessible via external IP
- [ ] No errors in logs
- [ ] Database connectivity working
- [ ] Core features functioning correctly

---

**Ready to deploy?** Run the update script and watch your changes go live! 🚀
