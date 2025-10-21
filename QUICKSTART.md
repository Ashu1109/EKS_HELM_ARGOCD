# Quick Start Guide - Deploy Chat App with Helm & ArgoCD

## TL;DR - Quick Commands

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Expose ArgoCD
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 3. Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# 4. Get ArgoCD URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 5. Update ArgoCD application manifests with your Git repo URL
# Edit argocd/*.yaml files and replace <YOUR-USERNAME>/<YOUR-REPO>

# 6. Update secrets (IMPORTANT!)
# Edit helm/*/values.yaml and update passwords and JWT_SECRET

# 7. Push to Git
git add helm/ argocd/ DEPLOYMENT.md QUICKSTART.md
git commit -m "Add Helm charts and ArgoCD applications"
git push origin main

# 8. Deploy applications
kubectl apply -f argocd/mongodb-application.yaml
kubectl apply -f argocd/backend-application.yaml
kubectl apply -f argocd/frontend-application.yaml

# 9. Wait for deployment (2-5 minutes)
kubectl get pods -n chat-app -w

# 10. Get application URL
kubectl get svc frontend -n chat-app
```

## Manual Helm Installation (Without ArgoCD)

If you prefer to deploy without ArgoCD:

```bash
# Create namespace
kubectl create namespace chat-app

# Deploy MongoDB
helm install mongodb ./helm/mongodb -n chat-app

# Deploy Backend
helm install backend ./helm/backend -n chat-app

# Deploy Frontend
helm install frontend ./helm/frontend -n chat-app

# Check status
helm list -n chat-app
kubectl get all -n chat-app
```

## Verify Everything Works

```bash
# Check all pods are running
kubectl get pods -n chat-app

# Check services
kubectl get svc -n chat-app

# Get frontend URL
kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Check logs
kubectl logs -l app.kubernetes.io/name=backend -n chat-app --tail=50
```

## Access Application

```bash
# Get the URL and open in browser
export FRONTEND_URL=$(kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Open: http://${FRONTEND_URL}"
```

## Clean Up

```bash
# Delete ArgoCD applications
kubectl delete -f argocd/

# Or if using Helm directly
helm uninstall mongodb backend frontend -n chat-app

# Delete namespace
kubectl delete namespace chat-app
```

## Troubleshooting

```bash
# Pods not starting?
kubectl describe pods -n chat-app

# Check events
kubectl get events -n chat-app --sort-by='.lastTimestamp'

# View logs
kubectl logs <pod-name> -n chat-app

# Restart a deployment
kubectl rollout restart deployment/<name> -n chat-app
```

For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)
