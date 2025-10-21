# Fixes Applied to Chat App Deployment

## Summary

This document outlines all the fixes applied to resolve deployment issues with the Full Stack Chat Application on AWS EKS using Helm and ArgoCD.

## Issues Fixed

### 1. Missing Helm Chart Configuration Fields

**Problem**: ArgoCD could not render Helm templates due to missing configuration fields in `values.yaml`.

**Error**:
```
failed to execute helm template: nil pointer evaluating interface {}.enabled
```

**Solution**: Added missing configuration to all Helm charts:
- Added `ingress.enabled: false`
- Added `httpRoute.enabled: false`

**Files Modified**:
- `helm/mongodb/values.yaml`
- `helm/backend/values.yaml`
- `helm/frontend/values.yaml`

**Commit**: `99fd3c7` - "Fix: Add missing httpRoute configuration to all Helm values"

---

### 2. AWS EBS CSI Driver Not Installed

**Problem**: MongoDB PersistentVolumeClaim was stuck in "Pending" state because EBS CSI driver was not installed.

**Error**:
```
Waiting for a volume to be created either by the external provisioner 'ebs.csi.aws.com'
or manually by the system administrator
```

**Solution**:
1. Installed AWS EBS CSI Driver using Helm:
   ```bash
   helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver -n kube-system
   ```

2. Added IAM permissions to node role:
   ```bash
   aws iam attach-role-policy \
     --role-name eksctl-my-cluster-nodegroup-standa-NodeInstanceRole-IIRHhadRcGTF \
     --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
   ```

**Result**: PersistentVolumeClaim successfully bound to a 5Gi EBS volume.

---

### 3. Nginx WebSocket Configuration for Socket.io

**Problem**: Socket.io WebSocket connections were failing with HTTP 400 errors. WebSocket upgrade requests were not being handled correctly.

**Error** (from logs):
```
GET /socket.io/?...&transport=websocket... HTTP/1.1" 400
```

**Solution**: Updated Nginx configuration with proper WebSocket support:

**Changes to `helm/frontend/values.yaml`**:
1. Added upstream backend configuration with keepalive
2. Added connection upgrade mapping
3. Configured proper proxy headers for WebSocket
4. Added long timeouts for WebSocket connections (7 days)
5. Disabled proxy buffering for real-time connections

**Key additions**:
```nginx
upstream backend_upstream {
    server backend:5001;
    keepalive 64;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

# WebSocket specific timeouts
proxy_connect_timeout 7d;
proxy_send_timeout 7d;
proxy_read_timeout 7d;

# Proper headers
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_buffering off;
```

**Commit**: `5f27380` - "Fix: Improve Nginx WebSocket configuration for Socket.io connections"

---

### 4. Socket.io Session Affinity (Sticky Sessions)

**Problem**: Socket.io connections were being dropped because load balancer was routing requests to different backend pods, breaking the session.

**Symptoms**:
- Frequent user disconnections
- Socket.io session errors
- Inconsistent WebSocket behavior

**Solution**: Added session affinity to backend service to ensure all requests from the same client IP go to the same backend pod.

**Changes to `helm/backend/values.yaml`**:
```yaml
service:
  type: ClusterIP
  port: 5001
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
```

**Changes to `helm/backend/templates/service.yaml`**:
Added session affinity configuration to the service template.

**Commit**: `96ea76f` - "Fix: Add session affinity (sticky sessions) for Socket.io WebSocket connections"

---

### 5. Cookie and JWT Token Forwarding

**Problem**: After successful login, API requests to get users were returning 401 Unauthorized errors because JWT tokens/cookies were not being forwarded from frontend to backend through the Nginx proxy.

**Error** (from logs):
```
POST /api/auth/login HTTP/1.1" 200  # Login successful
GET /api/messages/users HTTP/1.1" 401  # But users API returns unauthorized
```

**Symptoms**:
- Login works but user cannot access protected API endpoints
- "No users available" shown in UI
- 401 errors for authenticated API calls

**Solution**: Updated Nginx configuration to properly forward cookies and origin headers.

**Changes to `helm/frontend/values.yaml`**:
Added cookie forwarding headers to both `/api/` and `/socket.io/` locations:
```nginx
proxy_set_header Origin $http_origin;
proxy_set_header Cookie $http_cookie;
proxy_pass_header Set-Cookie;
```

These headers ensure that:
- Cookies are forwarded from client to backend
- Set-Cookie headers from backend reach the client
- Origin header is preserved for CORS

**Commit**: `cbf270a` - "Fix: Add Cookie and Origin headers forwarding for JWT authentication"

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                       │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              ArgoCD (GitOps)                        │ │
│  │  - Monitors Git Repository                          │ │
│  │  - Auto-syncs changes from main branch             │ │
│  └────────────────────────────────────────────────────┘ │
│                         │                                 │
│         ┌───────────────┼───────────────┐                │
│         │               │               │                │
│  ┌──────▼─────┐  ┌─────▼──────┐  ┌────▼──────┐         │
│  │  MongoDB   │  │  Backend   │  │ Frontend  │         │
│  │  (1 pod)   │  │  (2 pods)  │  │ (2 pods)  │         │
│  │            │  │            │  │           │         │
│  │  - PVC     │  │  - Session │  │  - Nginx  │         │
│  │  - EBS     │  │    Affinity│  │  - WS     │         │
│  └────────────┘  └────────────┘  └───────────┘         │
│                                         │                 │
│                           ┌─────────────▼─────────────┐  │
│                           │  AWS LoadBalancer (ELB)   │  │
│                           └───────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                          Internet Users
```

## Final Configuration

### Resources Deployed

**MongoDB**:
- 1 replica
- 5Gi PersistentVolume (AWS EBS GP2)
- Session affinity: None (single replica)

**Backend**:
- 2 replicas
- Session affinity: ClientIP (sticky sessions for Socket.io)
- Resources: 500m CPU, 512Mi memory

**Frontend**:
- 2 replicas
- LoadBalancer service (AWS ELB)
- Nginx with WebSocket support
- Resources: 200m CPU, 256Mi memory

### Access Information

**Frontend URL**:
```
http://a9d95714f5cab4a5ab73e2d9869e588f-1726112896.ap-south-1.elb.amazonaws.com
```

**Services**:
- Frontend: LoadBalancer on port 80
- Backend: ClusterIP on port 5001 (with session affinity)
- MongoDB: ClusterIP on port 27017

## Testing Checklist

- [x] MongoDB pod is running
- [x] PersistentVolumeClaim is bound
- [x] Backend pods are running (2/2)
- [x] Frontend pods are running (2/2)
- [x] LoadBalancer has external IP assigned
- [x] Application is accessible via browser
- [x] User registration works
- [x] User login works
- [x] Socket.io connections established
- [x] Cookie/JWT forwarding working
- [x] Protected API endpoints accessible after login
- [x] Users list loading correctly
- [ ] WebSocket connections stable (monitoring)
- [ ] Real-time messaging works
- [ ] No frequent disconnections

## Commands for Verification

```bash
# Check all pods
kubectl get pods -n chat-app

# Check services
kubectl get svc -n chat-app

# Check PVC
kubectl get pvc -n chat-app

# Check ArgoCD applications
kubectl get application -n argocd

# View backend logs
kubectl logs -l app.kubernetes.io/name=backend -n chat-app --tail=50

# View frontend logs
kubectl logs -l app.kubernetes.io/name=frontend -n chat-app --tail=50

# Check backend service configuration
kubectl get svc backend -n chat-app -o yaml | grep -A 5 "sessionAffinity"

# Check nginx config in frontend pod
kubectl exec <frontend-pod> -n chat-app -- cat /etc/nginx/conf.d/default.conf
```

## Git Commits

All fixes have been committed to the main branch:

1. `d10413c` - Fix: Add missing ingress configuration to mongodb values
2. `99fd3c7` - Fix: Add missing httpRoute configuration to all Helm values
3. `5f27380` - Fix: Improve Nginx WebSocket configuration for Socket.io connections
4. `96ea76f` - Fix: Add session affinity (sticky sessions) for Socket.io WebSocket connections
5. `cbf270a` - Fix: Add Cookie and Origin headers forwarding for JWT authentication

## Next Steps

1. Monitor application for WebSocket stability
2. Consider implementing Redis for Socket.io session sharing (for better multi-pod support)
3. Set up monitoring and alerting
4. Configure backup for MongoDB
5. Implement SSL/TLS with domain name
6. Review and update secrets management (use Kubernetes Secrets or AWS Secrets Manager)

## Notes

- All changes are managed via GitOps (ArgoCD)
- Any configuration changes should be made in Git repository
- ArgoCD will auto-sync changes from the main branch
- Session affinity timeout is set to 3 hours (10800 seconds)
- WebSocket proxy timeouts set to 7 days

---

**Last Updated**: 2025-10-21
**Status**: Deployed and Running
**Environment**: AWS EKS
