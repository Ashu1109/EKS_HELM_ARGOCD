# Helm Charts for Chat Application

This directory contains Helm charts for deploying the Full Stack Real-Time Chat Application on Kubernetes.

## Directory Structure

```
helm/
├── mongodb/          # MongoDB database chart
├── backend/          # Node.js/Express backend API chart
├── frontend/         # React frontend chart
├── production-values.yaml  # Production overrides example
└── README.md         # This file
```

## Charts Overview

### MongoDB Chart
- **Purpose**: Deploys MongoDB database
- **Features**:
  - Persistent storage with PVC
  - Configurable resources
  - Authentication enabled
- **Port**: 27017

### Backend Chart
- **Purpose**: Deploys Node.js/Express API with Socket.io
- **Features**:
  - Environment variable configuration
  - Horizontal pod autoscaling support
  - Resource limits and requests
- **Port**: 5001

### Frontend Chart
- **Purpose**: Deploys React application with Nginx
- **Features**:
  - Nginx reverse proxy configuration
  - LoadBalancer service for AWS EKS
  - Health checks (readiness/liveness probes)
  - Configurable nginx config via ConfigMap
- **Port**: 80

## Installation

### Prerequisites
- Kubernetes cluster (EKS, GKE, AKS, or local)
- Helm 3.x installed
- kubectl configured

### Install All Charts

```bash
# Create namespace
kubectl create namespace chat-app

# Install in order
helm install mongodb ./mongodb -n chat-app
helm install backend ./backend -n chat-app
helm install frontend ./frontend -n chat-app
```

### Install with Custom Values

```bash
helm install mongodb ./mongodb -f production-values.yaml -n chat-app
```

### Verify Installation

```bash
helm list -n chat-app
kubectl get all -n chat-app
```

## Configuration

### MongoDB Configuration

Key values in `mongodb/values.yaml`:

```yaml
replicaCount: 1
image:
  repository: mongo
  tag: "latest"

mongodb:
  auth:
    rootUsername: root
    rootPassword: admin  # CHANGE THIS!
  persistence:
    enabled: true
    size: 5Gi
    storageClass: gp2
```

### Backend Configuration

Key values in `backend/values.yaml`:

```yaml
replicaCount: 2
image:
  repository: iemafzal/backend
  tag: "v1"

backend:
  env:
    - name: MONGODB_URI
      value: "mongodb://root:admin@mongodb:27017/chatApp?authSource=admin"
    - name: JWT_SECRET
      value: "your_jwt_secret"  # CHANGE THIS!
```

### Frontend Configuration

Key values in `frontend/values.yaml`:

```yaml
replicaCount: 2
image:
  repository: iemafzal/frontend
  tag: "v1"

service:
  type: LoadBalancer  # Creates AWS ELB
  port: 80
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade mongodb ./mongodb -n chat-app

# Upgrade with custom values file
helm upgrade backend ./backend -f custom-values.yaml -n chat-app
```

## Uninstalling

```bash
# Uninstall specific chart
helm uninstall mongodb -n chat-app

# Uninstall all
helm uninstall mongodb backend frontend -n chat-app

# Delete namespace
kubectl delete namespace chat-app
```

## Customization

### Override Values

Create a custom values file:

```yaml
# my-values.yaml
replicaCount: 5
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
```

Install with custom values:

```bash
helm install backend ./backend -f my-values.yaml -n chat-app
```

### Template Customization

To customize templates, edit files in `templates/` directory of each chart:
- `deployment.yaml` - Pod specifications
- `service.yaml` - Service configuration
- `configmap.yaml` - ConfigMap (frontend)
- `pvc.yaml` - Persistent Volume Claim (mongodb)

## Helm Commands Reference

```bash
# List releases
helm list -n chat-app

# Get release values
helm get values mongodb -n chat-app

# Get release manifest
helm get manifest mongodb -n chat-app

# Rollback to previous version
helm rollback mongodb 1 -n chat-app

# Test templates
helm template ./mongodb

# Lint charts
helm lint ./mongodb
helm lint ./backend
helm lint ./frontend

# Package charts
helm package ./mongodb
```

## Using with ArgoCD

See ArgoCD application manifests in `../argocd/` directory.

ArgoCD provides:
- GitOps workflow
- Automated syncing
- Declarative configuration
- Version control
- Rollback capabilities

## Production Recommendations

1. **Security:**
   ```yaml
   # Use Kubernetes secrets instead of plain text
   backend:
     env:
       - name: JWT_SECRET
         valueFrom:
           secretKeyRef:
             name: backend-secrets
             key: jwt-secret
   ```

2. **Resources:**
   ```yaml
   resources:
     limits:
       cpu: 1000m
       memory: 1Gi
     requests:
       cpu: 500m
       memory: 512Mi
   ```

3. **Auto-scaling:**
   ```yaml
   autoscaling:
     enabled: true
     minReplicas: 3
     maxReplicas: 10
     targetCPUUtilizationPercentage: 70
   ```

4. **Storage:**
   ```yaml
   mongodb:
     persistence:
       storageClass: gp3  # Use GP3 for better performance
       size: 20Gi  # Increase for production
   ```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n chat-app

# Describe pod
kubectl describe pod <pod-name> -n chat-app

# Check logs
kubectl logs <pod-name> -n chat-app
```

### Helm release failed

```bash
# Check release status
helm status mongodb -n chat-app

# Get release history
helm history mongodb -n chat-app

# Rollback if needed
helm rollback mongodb 1 -n chat-app
```

### Values not applied

```bash
# Verify applied values
helm get values mongodb -n chat-app

# Re-upgrade with correct values
helm upgrade mongodb ./mongodb -f values.yaml -n chat-app
```

## Support

For issues and questions:
- Check logs: `kubectl logs <pod-name> -n chat-app`
- Review values: `helm get values <release> -n chat-app`
- See main documentation: [DEPLOYMENT.md](../DEPLOYMENT.md)
- GitHub Issues: [Project Issues](https://github.com/iemafzalhassan/full-stack_chatApp/issues)
