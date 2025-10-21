# Chat App Deployment Guide - Helm & ArgoCD on AWS EKS

This guide provides step-by-step instructions to deploy the Full Stack Real-Time Chat Application using Helm and ArgoCD on AWS EKS.

## Prerequisites

- AWS EKS cluster configured and running
- `kubectl` configured to access your EKS cluster
- `helm` CLI installed (v3.0+)
- Git repository for your application code
- AWS CLI configured

## Architecture Overview

The application consists of three main components:
- **MongoDB**: Database for storing chat data
- **Backend**: Node.js/Express API with Socket.io
- **Frontend**: React application with Nginx

## Step 1: Verify EKS Cluster Access

```bash
# Verify kubectl is configured
kubectl cluster-info

# Check nodes
kubectl get nodes

# Verify you're connected to the correct cluster
kubectl config current-context
```

## Step 2: Install ArgoCD on EKS

### 2.1 Create ArgoCD namespace

```bash
kubectl create namespace argocd
```

### 2.2 Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2.3 Wait for ArgoCD pods to be ready

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 2.4 Expose ArgoCD Server

**Option A: Using LoadBalancer (Recommended for EKS)**

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

**Option B: Using Port Forward (for testing)**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 2.5 Get ArgoCD Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### 2.6 Access ArgoCD UI

**If using LoadBalancer:**

```bash
# Get the LoadBalancer URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Access ArgoCD at: `https://<LOADBALANCER-URL>`

**If using Port Forward:**

Access ArgoCD at: `https://localhost:8080`

Login with:
- Username: `admin`
- Password: (from step 2.5)

### 2.7 Install ArgoCD CLI (Optional but Recommended)

**MacOS:**
```bash
brew install argocd
```

**Linux:**
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

**Login via CLI:**
```bash
argocd login <ARGOCD-SERVER-URL> --username admin --password <PASSWORD>
```

## Step 3: Push Helm Charts to Git Repository

### 3.1 Commit your Helm charts

```bash
cd /path/to/full-stack_chatApp

# Add all Helm charts
git add helm/
git add argocd/

# Commit changes
git commit -m "Add Helm charts and ArgoCD applications"

# Push to your repository
git push origin main
```

### 3.2 Update ArgoCD Application Manifests

Edit the following files and replace `<YOUR-USERNAME>/<YOUR-REPO>` with your actual GitHub repository:

- `argocd/mongodb-application.yaml`
- `argocd/backend-application.yaml`
- `argocd/frontend-application.yaml`

Example:
```yaml
source:
  repoURL: https://github.com/yourusername/full-stack_chatApp.git
  targetRevision: main
```

**Important**: Update JWT_SECRET and MongoDB credentials in values.yaml files before deployment!

## Step 4: Configure Secrets (IMPORTANT!)

### 4.1 Update MongoDB Credentials

Edit `helm/mongodb/values.yaml`:
```yaml
mongodb:
  auth:
    rootUsername: root
    rootPassword: <STRONG-PASSWORD>  # Change this!
```

### 4.2 Update Backend JWT Secret

Edit `helm/backend/values.yaml`:
```yaml
backend:
  env:
    - name: JWT_SECRET
      value: "<STRONG-JWT-SECRET>"  # Change this!
```

### 4.3 Update MongoDB Connection String in Backend

Edit `helm/backend/values.yaml`:
```yaml
backend:
  env:
    - name: MONGODB_URI
      value: "mongodb://root:<YOUR-PASSWORD>@mongodb:27017/chatApp?authSource=admin"
```

**Better Approach - Use Kubernetes Secrets:**

```bash
# Create a secret for MongoDB credentials
kubectl create secret generic mongodb-credentials \
  --from-literal=root-password=<YOUR-PASSWORD> \
  -n chat-app

# Create a secret for Backend
kubectl create secret generic backend-secrets \
  --from-literal=jwt-secret=<YOUR-JWT-SECRET> \
  --from-literal=mongodb-uri='mongodb://root:<YOUR-PASSWORD>@mongodb:27017/chatApp?authSource=admin' \
  -n chat-app
```

## Step 5: Deploy Applications with ArgoCD

### 5.1 Deploy MongoDB First

```bash
kubectl apply -f argocd/mongodb-application.yaml
```

### 5.2 Verify MongoDB Deployment

```bash
# Check ArgoCD application status
kubectl get application -n argocd

# Check MongoDB pods
kubectl get pods -n chat-app -l app.kubernetes.io/name=mongodb

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb -n chat-app --timeout=300s
```

### 5.3 Deploy Backend

```bash
kubectl apply -f argocd/backend-application.yaml
```

### 5.4 Verify Backend Deployment

```bash
# Check backend pods
kubectl get pods -n chat-app -l app.kubernetes.io/name=backend

# Check backend logs
kubectl logs -f -l app.kubernetes.io/name=backend -n chat-app
```

### 5.5 Deploy Frontend

```bash
kubectl apply -f argocd/frontend-application.yaml
```

### 5.6 Verify Frontend Deployment

```bash
# Check frontend pods
kubectl get pods -n chat-app -l app.kubernetes.io/name=frontend

# Check all services
kubectl get svc -n chat-app
```

## Step 6: Access Your Application

### 6.1 Get Frontend LoadBalancer URL

```bash
kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 6.2 Access the Application

```bash
# Get the URL
export FRONTEND_URL=$(kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://${FRONTEND_URL}"
```

Open your browser and navigate to the URL. It may take a few minutes for the AWS LoadBalancer to be provisioned.

## Step 7: Monitor Deployments

### 7.1 Using ArgoCD UI

Access the ArgoCD UI and you'll see all three applications:
- `chat-app-mongodb`
- `chat-app-backend`
- `chat-app-frontend`

### 7.2 Using kubectl

```bash
# Get all resources in chat-app namespace
kubectl get all -n chat-app

# Check application health
kubectl get application -n argocd

# View ArgoCD application details
argocd app get chat-app-frontend
argocd app get chat-app-backend
argocd app get chat-app-mongodb
```

### 7.3 View Logs

```bash
# MongoDB logs
kubectl logs -f -l app.kubernetes.io/name=mongodb -n chat-app

# Backend logs
kubectl logs -f -l app.kubernetes.io/name=backend -n chat-app

# Frontend logs
kubectl logs -f -l app.kubernetes.io/name=frontend -n chat-app
```

## Step 8: Verify Application Health

### 8.1 Test Database Connection

```bash
# Connect to MongoDB pod
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=mongodb -n chat-app -o jsonpath='{.items[0].metadata.name}') -n chat-app -- mongosh -u root -p admin

# In MongoDB shell:
show dbs
use chatApp
show collections
exit
```

### 8.2 Test Backend API

```bash
# Port-forward to backend
kubectl port-forward svc/backend -n chat-app 5001:5001

# In another terminal, test the API
curl http://localhost:5001/api/health
```

### 8.3 Test Frontend

Access the frontend LoadBalancer URL in your browser and verify:
- Login page loads
- User registration works
- Real-time messaging works
- Socket.io connections are established

## Troubleshooting

### Common Issues

**1. Pods not starting:**

```bash
# Check pod status
kubectl get pods -n chat-app

# Describe problematic pod
kubectl describe pod <POD-NAME> -n chat-app

# Check events
kubectl get events -n chat-app --sort-by='.lastTimestamp'
```

**2. ArgoCD Application OutOfSync:**

```bash
# Sync manually
argocd app sync chat-app-mongodb
argocd app sync chat-app-backend
argocd app sync chat-app-frontend
```

**3. MongoDB Connection Issues:**

```bash
# Check MongoDB service
kubectl get svc mongodb -n chat-app

# Verify environment variables in backend
kubectl exec $(kubectl get pod -l app.kubernetes.io/name=backend -n chat-app -o jsonpath='{.items[0].metadata.name}') -n chat-app -- env | grep MONGO
```

**4. Frontend Cannot Reach Backend:**

```bash
# Check backend service
kubectl get svc backend -n chat-app

# Test connectivity from frontend pod
kubectl exec $(kubectl get pod -l app.kubernetes.io/name=frontend -n chat-app -o jsonpath='{.items[0].metadata.name}') -n chat-app -- curl http://backend:5001/api/health
```

**5. LoadBalancer Pending:**

```bash
# Check service status
kubectl describe svc frontend -n chat-app

# Verify AWS Load Balancer Controller is installed
kubectl get deployment -n kube-system aws-load-balancer-controller
```

If AWS Load Balancer Controller is not installed:
```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<YOUR-CLUSTER-NAME>
```

## Updating the Application

### Using GitOps (Recommended)

1. Make changes to Helm values or templates
2. Commit and push to Git:
   ```bash
   git add .
   git commit -m "Update configuration"
   git push
   ```
3. ArgoCD will automatically detect changes and sync (if auto-sync is enabled)

### Manual Sync

```bash
# Sync specific application
argocd app sync chat-app-frontend

# Sync all applications
argocd app sync chat-app-mongodb chat-app-backend chat-app-frontend
```

### Update Image Tags

Edit `helm/<component>/values.yaml`:
```yaml
image:
  tag: "v2"  # Update version
```

Commit, push, and ArgoCD will deploy the new version.

## Scaling the Application

### Scale using Helm values

Edit `helm/backend/values.yaml`:
```yaml
replicaCount: 5  # Scale to 5 replicas
```

Or use kubectl:
```bash
kubectl scale deployment backend -n chat-app --replicas=5
```

### Enable Auto-Scaling

Edit `helm/backend/values.yaml`:
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## Clean Up

### Delete Applications

```bash
# Delete ArgoCD applications
kubectl delete -f argocd/mongodb-application.yaml
kubectl delete -f argocd/backend-application.yaml
kubectl delete -f argocd/frontend-application.yaml

# Or using ArgoCD CLI
argocd app delete chat-app-mongodb --cascade
argocd app delete chat-app-backend --cascade
argocd app delete chat-app-frontend --cascade

# Delete namespace
kubectl delete namespace chat-app
```

### Uninstall ArgoCD

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## Production Considerations

1. **Security:**
   - Use Kubernetes Secrets or AWS Secrets Manager for sensitive data
   - Enable TLS/SSL for all services
   - Implement Network Policies
   - Use RBAC for ArgoCD access

2. **Monitoring:**
   - Set up Prometheus and Grafana
   - Configure CloudWatch logs
   - Enable ArgoCD notifications

3. **Backup:**
   - Configure automated MongoDB backups
   - Backup PersistentVolumes using EBS snapshots
   - Export ArgoCD application configurations

4. **High Availability:**
   - Use multiple replicas for all services
   - Configure pod anti-affinity rules
   - Use multiple availability zones

5. **Cost Optimization:**
   - Use appropriate instance types
   - Implement cluster autoscaling
   - Monitor resource usage

## References

- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

For issues and questions:
- Check application logs: `kubectl logs -f <pod-name> -n chat-app`
- Review ArgoCD application status in the UI
- Check GitHub issues: [Project Issues](https://github.com/iemafzalhassan/full-stack_chatApp/issues)
