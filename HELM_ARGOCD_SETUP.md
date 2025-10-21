# Helm & ArgoCD Setup Summary

## What Has Been Created

This setup provides a complete GitOps deployment solution for the Chat Application using Helm and ArgoCD on AWS EKS.

## File Structure

```
full-stack_chatApp/
├── helm/
│   ├── mongodb/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── pvc.yaml
│   │       ├── namespace.yaml
│   │       ├── serviceaccount.yaml
│   │       └── hpa.yaml
│   ├── backend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── namespace.yaml
│   │       ├── serviceaccount.yaml
│   │       └── hpa.yaml
│   ├── frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       ├── namespace.yaml
│   │       ├── serviceaccount.yaml
│   │       └── hpa.yaml
│   ├── production-values.yaml
│   └── README.md
├── argocd/
│   ├── mongodb-application.yaml
│   ├── backend-application.yaml
│   └── frontend-application.yaml
├── DEPLOYMENT.md
├── QUICKSTART.md
└── HELM_ARGOCD_SETUP.md (this file)
```

## Components

### 1. Helm Charts (3 charts)

**MongoDB Chart** (`helm/mongodb/`)
- Deploys MongoDB with persistent storage
- Configurable authentication
- Resource limits and requests
- PersistentVolumeClaim for data persistence

**Backend Chart** (`helm/backend/`)
- Node.js/Express API with Socket.io
- Environment variable configuration
- Auto-scaling support
- Resource management

**Frontend Chart** (`helm/frontend/`)
- React application with Nginx
- LoadBalancer service for AWS EKS
- Nginx configuration via ConfigMap
- Health probes configured

### 2. ArgoCD Applications (3 applications)

Each component has its own ArgoCD Application manifest:
- `mongodb-application.yaml`
- `backend-application.yaml`
- `frontend-application.yaml`

Features:
- Automated sync from Git repository
- Self-healing enabled
- Auto-pruning of resources
- Retry logic on failures

### 3. Documentation

- **DEPLOYMENT.md** - Comprehensive deployment guide with all steps
- **QUICKSTART.md** - Quick reference for fast deployment
- **helm/README.md** - Helm charts documentation
- **HELM_ARGOCD_SETUP.md** - This summary file

## Quick Deployment Steps

### Option 1: Using ArgoCD (Recommended)

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Update Git repository URLs in argocd/*.yaml files
# Replace: <YOUR-USERNAME>/<YOUR-REPO>

# 3. Update secrets in helm/*/values.yaml
# Change: JWT_SECRET, MongoDB passwords

# 4. Push to Git
git add .
git commit -m "Configure Helm and ArgoCD"
git push

# 5. Deploy via ArgoCD
kubectl apply -f argocd/mongodb-application.yaml
kubectl apply -f argocd/backend-application.yaml
kubectl apply -f argocd/frontend-application.yaml

# 6. Access application
kubectl get svc frontend -n chat-app
```

### Option 2: Using Helm Directly

```bash
# 1. Create namespace
kubectl create namespace chat-app

# 2. Install charts
helm install mongodb ./helm/mongodb -n chat-app
helm install backend ./helm/backend -n chat-app
helm install frontend ./helm/frontend -n chat-app

# 3. Verify
helm list -n chat-app
kubectl get all -n chat-app
```

## Important Configuration Changes

### Before Deployment - Update These Values!

1. **Git Repository URL** (in all `argocd/*.yaml` files):
   ```yaml
   source:
     repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO.git
   ```

2. **MongoDB Password** (`helm/mongodb/values.yaml`):
   ```yaml
   mongodb:
     auth:
       rootPassword: "CHANGE_THIS_PASSWORD"
   ```

3. **Backend JWT Secret** (`helm/backend/values.yaml`):
   ```yaml
   backend:
     env:
       - name: JWT_SECRET
         value: "CHANGE_THIS_SECRET"
   ```

4. **MongoDB Connection String** (`helm/backend/values.yaml`):
   ```yaml
   backend:
     env:
       - name: MONGODB_URI
         value: "mongodb://root:YOUR_PASSWORD@mongodb:27017/chatApp?authSource=admin"
   ```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                   │
│                                                       │
│  ┌────────────────────────────────────────────────┐ │
│  │              ArgoCD (GitOps)                    │ │
│  │  - Monitors Git Repository                      │ │
│  │  - Auto-syncs changes                           │ │
│  │  - Manages deployments                          │ │
│  └────────────────────────────────────────────────┘ │
│                         │                             │
│         ┌───────────────┼───────────────┐            │
│         │               │               │            │
│  ┌──────▼─────┐  ┌─────▼──────┐  ┌────▼──────┐     │
│  │  MongoDB   │  │  Backend   │  │ Frontend  │     │
│  │  Chart     │  │  Chart     │  │  Chart    │     │
│  │            │  │            │  │           │     │
│  │  - DB      │  │  - API     │  │  - React  │     │
│  │  - PVC     │  │  - Socket  │  │  - Nginx  │     │
│  │  - Service │  │  - Service │  │  - LB     │     │
│  └────────────┘  └────────────┘  └───────────┘     │
│                                                       │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
                  Internet Users
```

## Key Features

1. **GitOps Workflow**
   - All configuration in Git
   - Version controlled deployments
   - Automated synchronization
   - Easy rollbacks

2. **High Availability**
   - Multiple replicas per service
   - Auto-scaling support
   - Health checks configured
   - Load balancing

3. **Security**
   - Namespaced deployments
   - Service accounts
   - ConfigMap for configuration
   - Secrets management ready

4. **Monitoring & Observability**
   - ArgoCD UI for deployment status
   - Health status tracking
   - Sync state monitoring
   - Event logging

5. **Production Ready**
   - Resource limits configured
   - Persistent storage for MongoDB
   - AWS LoadBalancer integration
   - Auto-healing enabled

## Accessing Components

### ArgoCD UI

```bash
# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Application Frontend

```bash
# Get application URL
kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### MongoDB (Internal)

```bash
# Port-forward for local access
kubectl port-forward svc/mongodb -n chat-app 27017:27017

# Connect via mongosh
mongosh mongodb://root:admin@localhost:27017/chatApp?authSource=admin
```

### Backend API (Internal)

```bash
# Port-forward for testing
kubectl port-forward svc/backend -n chat-app 5001:5001

# Test API
curl http://localhost:5001/api/health
```

## Monitoring Deployment

### Using ArgoCD UI
- View application sync status
- See resource health
- View deployment history
- Trigger manual sync
- Rollback to previous versions

### Using kubectl

```bash
# Watch pods
kubectl get pods -n chat-app -w

# Check all resources
kubectl get all -n chat-app

# View events
kubectl get events -n chat-app --sort-by='.lastTimestamp'

# Check ArgoCD applications
kubectl get application -n argocd
```

### Using Helm

```bash
# List releases
helm list -n chat-app

# Get release status
helm status mongodb -n chat-app

# View release values
helm get values mongodb -n chat-app
```

## Updating the Application

### GitOps Way (Recommended)

1. Update values in `helm/*/values.yaml`
2. Commit and push to Git:
   ```bash
   git add helm/
   git commit -m "Update configuration"
   git push
   ```
3. ArgoCD automatically syncs changes

### Manual Helm Update

```bash
# Update values and upgrade
helm upgrade mongodb ./helm/mongodb -n chat-app
```

### Update Image Tags

Edit `helm/<component>/values.yaml`:
```yaml
image:
  tag: "v2.0.0"  # New version
```

Commit, push, and ArgoCD will deploy.

## Scaling

### Manual Scaling

```bash
kubectl scale deployment backend -n chat-app --replicas=5
```

### Auto-Scaling

Enable in `values.yaml`:
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## Troubleshooting

### Common Commands

```bash
# Check pod logs
kubectl logs -f <pod-name> -n chat-app

# Describe problematic pod
kubectl describe pod <pod-name> -n chat-app

# Check ArgoCD application
argocd app get chat-app-backend

# Force sync
argocd app sync chat-app-backend

# View diff
argocd app diff chat-app-backend
```

### Common Issues

1. **Pods CrashLoopBackOff**: Check logs with `kubectl logs`
2. **ArgoCD OutOfSync**: Check Git repo URL and credentials
3. **LoadBalancer Pending**: Verify AWS Load Balancer Controller
4. **MongoDB Connection Failed**: Check credentials and service name

## Next Steps

1. ✅ Push all changes to Git
2. ✅ Update repository URLs in ArgoCD manifests
3. ✅ Update secrets and passwords
4. ✅ Deploy ArgoCD
5. ✅ Deploy applications
6. ⬜ Set up monitoring (Prometheus/Grafana)
7. ⬜ Configure alerts
8. ⬜ Set up backup for MongoDB
9. ⬜ Implement CI/CD pipeline
10. ⬜ Configure domain and SSL/TLS

## Resources

- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

See detailed guides:
- **Full Deployment**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Helm Charts**: [helm/README.md](helm/README.md)

GitHub Issues: [Project Repository](https://github.com/iemafzalhassan/full-stack_chatApp)

---

**Created with Helm & ArgoCD for AWS EKS**
