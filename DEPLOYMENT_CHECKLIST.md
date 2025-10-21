# Deployment Checklist

Use this checklist to ensure a smooth deployment of the Chat Application using Helm and ArgoCD on AWS EKS.

## Pre-Deployment Checklist

### ✅ Prerequisites

- [ ] AWS EKS cluster is running
- [ ] `kubectl` is installed and configured
- [ ] `helm` CLI is installed (v3.0+)
- [ ] `argocd` CLI is installed (optional but recommended)
- [ ] Git repository is created and accessible
- [ ] AWS CLI is configured with proper credentials

### ✅ Configuration Updates

#### 1. Update Git Repository URLs

- [ ] Edit `argocd/mongodb-application.yaml` - Replace `<YOUR-USERNAME>/<YOUR-REPO>`
- [ ] Edit `argocd/backend-application.yaml` - Replace `<YOUR-USERNAME>/<YOUR-REPO>`
- [ ] Edit `argocd/frontend-application.yaml` - Replace `<YOUR-USERNAME>/<YOUR-REPO>`

#### 2. Update MongoDB Credentials

- [ ] Edit `helm/mongodb/values.yaml`
- [ ] Change `rootPassword` from `admin` to a strong password
- [ ] Document the password securely (use password manager)

#### 3. Update Backend Configuration

- [ ] Edit `helm/backend/values.yaml`
- [ ] Update `JWT_SECRET` to a strong secret key
- [ ] Update `MONGODB_URI` with the MongoDB password you set
- [ ] Verify `PORT` and `NODE_ENV` are correct

#### 4. Review Frontend Configuration

- [ ] Edit `helm/frontend/values.yaml`
- [ ] Verify `service.type` is `LoadBalancer` for EKS
- [ ] Review nginx configuration if needed
- [ ] Verify image repository and tag

### ✅ Security (Important!)

- [ ] All default passwords are changed
- [ ] JWT_SECRET is a strong, random string
- [ ] Credentials are NOT committed to public repository
- [ ] Consider using Kubernetes Secrets instead of plain values
- [ ] Review resource limits and quotas

## Deployment Steps

### ✅ Step 1: Push Code to Git

- [ ] All Helm charts are in `helm/` directory
- [ ] All ArgoCD manifests are in `argocd/` directory
- [ ] Run: `git add helm/ argocd/ *.md`
- [ ] Run: `git commit -m "Add Helm and ArgoCD deployment"`
- [ ] Run: `git push origin main`
- [ ] Verify files are visible in GitHub/GitLab

### ✅ Step 2: Verify EKS Cluster

- [ ] Run: `kubectl cluster-info`
- [ ] Run: `kubectl get nodes`
- [ ] All nodes show `Ready` status
- [ ] You're connected to the correct cluster

### ✅ Step 3: Install ArgoCD

- [ ] Run: `kubectl create namespace argocd`
- [ ] Run: `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- [ ] Wait for pods: `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s`
- [ ] Expose ArgoCD: `kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'`
- [ ] Get password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- [ ] Save password securely

### ✅ Step 4: Access ArgoCD UI

- [ ] Get URL: `kubectl get svc argocd-server -n argocd`
- [ ] Access ArgoCD UI via LoadBalancer URL
- [ ] Login with username `admin` and saved password
- [ ] Change admin password (Settings > Accounts)

### ✅ Step 5: Deploy Applications

#### Deploy MongoDB

- [ ] Run: `kubectl apply -f argocd/mongodb-application.yaml`
- [ ] Check in ArgoCD UI: Application appears
- [ ] Wait for sync: Application status shows "Healthy" and "Synced"
- [ ] Verify pods: `kubectl get pods -n chat-app -l app.kubernetes.io/name=mongodb`
- [ ] Pod status is "Running"

#### Deploy Backend

- [ ] Run: `kubectl apply -f argocd/backend-application.yaml`
- [ ] Check in ArgoCD UI: Application appears
- [ ] Wait for sync: Application status shows "Healthy" and "Synced"
- [ ] Verify pods: `kubectl get pods -n chat-app -l app.kubernetes.io/name=backend`
- [ ] All pods status is "Running"
- [ ] Check logs: `kubectl logs -l app.kubernetes.io/name=backend -n chat-app --tail=50`
- [ ] No critical errors in logs

#### Deploy Frontend

- [ ] Run: `kubectl apply -f argocd/frontend-application.yaml`
- [ ] Check in ArgoCD UI: Application appears
- [ ] Wait for sync: Application status shows "Healthy" and "Synced"
- [ ] Verify pods: `kubectl get pods -n chat-app -l app.kubernetes.io/name=frontend`
- [ ] All pods status is "Running"

### ✅ Step 6: Verify Services

- [ ] Run: `kubectl get svc -n chat-app`
- [ ] MongoDB service exists (ClusterIP)
- [ ] Backend service exists (ClusterIP)
- [ ] Frontend service exists (LoadBalancer)
- [ ] Frontend has EXTERNAL-IP assigned (may take 2-5 minutes)

### ✅ Step 7: Access Application

- [ ] Get URL: `kubectl get svc frontend -n chat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
- [ ] Open URL in browser
- [ ] Application loads successfully
- [ ] Can register a new user
- [ ] Can login
- [ ] Can send messages
- [ ] Real-time messaging works
- [ ] Socket.io connection is stable

## Post-Deployment Verification

### ✅ Health Checks

- [ ] All pods in `chat-app` namespace are Running
- [ ] All ArgoCD applications are "Healthy" and "Synced"
- [ ] Frontend LoadBalancer is accessible
- [ ] Backend can connect to MongoDB
- [ ] No CrashLoopBackOff or Error states

### ✅ Functionality Tests

- [ ] User registration works
- [ ] User login works
- [ ] User can send messages
- [ ] Messages appear in real-time
- [ ] User list updates correctly
- [ ] Profile pictures can be uploaded
- [ ] Online/offline status works
- [ ] Page refresh maintains login state

### ✅ Logs Review

- [ ] Check MongoDB logs: No errors
- [ ] Check Backend logs: No critical errors
- [ ] Check Frontend logs: No 502/503 errors
- [ ] ArgoCD shows no sync errors

### ✅ Resource Check

- [ ] Pods are not using excessive CPU
- [ ] Pods are not using excessive memory
- [ ] No pods are being OOMKilled
- [ ] PersistentVolumeClaim for MongoDB is Bound

## Monitoring Setup (Optional but Recommended)

- [ ] Install Prometheus
- [ ] Install Grafana
- [ ] Configure dashboards
- [ ] Set up alerts for pod failures
- [ ] Set up alerts for high resource usage
- [ ] Configure ArgoCD notifications

## Backup Setup (Recommended)

- [ ] Configure MongoDB backup strategy
- [ ] Set up PVC snapshots
- [ ] Export ArgoCD application configurations
- [ ] Document restore procedures

## Documentation

- [ ] Update team documentation with URLs
- [ ] Share ArgoCD credentials with team (securely)
- [ ] Document any custom configurations
- [ ] Create runbook for common issues

## Security Hardening (Production)

- [ ] Move secrets to Kubernetes Secrets
- [ ] Enable TLS for all services
- [ ] Configure Network Policies
- [ ] Set up RBAC for ArgoCD
- [ ] Enable audit logging
- [ ] Review and apply security policies
- [ ] Scan images for vulnerabilities

## Performance Optimization

- [ ] Review and adjust resource limits
- [ ] Enable HPA (Horizontal Pod Autoscaler)
- [ ] Configure appropriate storage class (gp3)
- [ ] Set up pod anti-affinity for HA
- [ ] Review and optimize container images

## Troubleshooting Quick Reference

If something goes wrong:

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n chat-app
kubectl logs <pod-name> -n chat-app
kubectl get events -n chat-app --sort-by='.lastTimestamp'
```

**ArgoCD not syncing:**
```bash
argocd app get <app-name>
argocd app sync <app-name> --force
kubectl get application -n argocd
```

**Application not accessible:**
```bash
kubectl get svc -n chat-app
kubectl describe svc frontend -n chat-app
kubectl get pods -n chat-app
```

**MongoDB connection issues:**
```bash
kubectl exec -it <backend-pod> -n chat-app -- env | grep MONGO
kubectl exec -it <mongodb-pod> -n chat-app -- mongosh -u root -p <password>
```

## Final Verification

- [ ] All checklist items above are completed
- [ ] Application is accessible via LoadBalancer URL
- [ ] All features work as expected
- [ ] No critical errors in logs
- [ ] Team is notified of deployment
- [ ] Documentation is updated
- [ ] Credentials are stored securely

## Next Steps

After successful deployment:

1. Set up monitoring and alerting
2. Configure automated backups
3. Implement CI/CD pipeline
4. Set up domain name and SSL/TLS
5. Configure auto-scaling policies
6. Perform load testing
7. Create disaster recovery plan
8. Schedule regular security audits

---

**Deployment Date:** _________________

**Deployed By:** _________________

**Environment:** AWS EKS

**Status:** ⬜ Pending  ⬜ In Progress  ⬜ Completed  ⬜ Failed

**Notes:**
_______________________________________________________
_______________________________________________________
_______________________________________________________
