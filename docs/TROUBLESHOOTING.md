# Troubleshooting Guide

Common issues and solutions for Sligo Cloud deployment.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Pod Issues](#pod-issues)
- [Networking Issues](#networking-issues)
- [Database Issues](#database-issues)
- [Ingress Issues](#ingress-issues)
- [Performance Issues](#performance-issues)

---

## Installation Issues

### Helm Install Fails

**Symptom:** `helm install` command fails

**Common causes:**

1. **Missing secrets**
```bash
# Check if all secrets exist
kubectl get secrets -n sligo

# Expected secrets:
# - nextjs-secrets
# - backend-secrets
# - mcp-gateway-secrets
# - postgres-secrets (or postgres-external-secrets)
```

**Solution:** Create missing secrets (see [SECRETS.md](./SECRETS.md))

2. **Invalid values**
```bash
# Validate your values file
helm template test sligo/sligo-cloud -f values-production.yaml
```

**Solution:** Fix syntax errors in values file

3. **Namespace doesn't exist**
```bash
# Create namespace
kubectl create namespace sligo
```

## Pod Issues

### Pods Not Starting (Pending)

**Symptom:** Pods stuck in Pending state

```bash
kubectl get pods -n sligo
# NAME                           READY   STATUS    RESTARTS   AGE
# sligo-app-xxx                  0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n sligo
```

**Common causes:**

1. **Insufficient resources**
   - Error: `Insufficient cpu` or `Insufficient memory`
   - **Solution:** Scale down other workloads or add nodes

2. **Image pull errors**
   - Error: `ErrImagePull` or `ImagePullBackOff`
   - **Solution:** Check image repository URLs and credentials

3. **Storage class not available**
   - Error: `Pending PersistentVolumeClaim`
   - **Solution:** Verify storage class exists

### Pods CrashLooping

**Symptom:** Pods restarting repeatedly

```bash
kubectl get pods -n sligo
# NAME                           READY   STATUS             RESTARTS   AGE
# sligo-app-xxx                  0/1     CrashLoopBackOff   5          10m
```

**Diagnosis:**
```bash
# Check logs
kubectl logs <pod-name> -n sligo --previous

# Check events
kubectl describe pod <pod-name> -n sligo
```

**Common causes:**

1. **Missing environment variables**
   - Check logs for "environment variable not set" errors
   - **Solution:** Verify secrets are created correctly

2. **Database connection issues**
   - Check logs for connection errors
   - **Solution:** Verify database credentials and connectivity

3. **Application errors**
   - Check logs for application-specific errors
   - **Solution:** Contact support with logs

### Pods Not Ready

**Symptom:** Pods running but not ready

```bash
kubectl get pods -n sligo
# NAME                           READY   STATUS    RESTARTS   AGE
# sligo-app-xxx                  0/1     Running   0          10m
```

**Diagnosis:**
```bash
# Check readiness probe
kubectl describe pod <pod-name> -n sligo | grep -A 10 "Readiness"

# Check logs
kubectl logs <pod-name> -n sligo
```

**Common causes:**

1. **Readiness probe failing**
   - Probe endpoint not responding
   - **Solution:** Verify health endpoint is working

2. **Application slow to start**
   - Increase `initialDelaySeconds` in readiness probe
   - **Solution:** Update values:
   ```yaml
   app:
     readinessProbe:
       initialDelaySeconds: 60  # Increase from 15
   ```

## Networking Issues

### Cannot Access Application

**Symptom:** Application URL not accessible

**Diagnosis:**
```bash
# Check ingress
kubectl get ingress -n sligo

# Check services
kubectl get svc -n sligo

# Check ALB creation (AWS)
kubectl describe ingress -n sligo
```

**Common causes:**

1. **Ingress not created**
   - No ALB provisioned
   - **Solution:** Check ingress controller is installed

2. **DNS not configured**
   - Domain not pointing to ALB
   - **Solution:** Create CNAME record

3. **Security group blocking traffic**
   - ALB security group too restrictive
   - **Solution:** Allow inbound traffic on ports 80/443

### Pods Cannot Connect to Database

**Symptom:** Application logs show database connection errors

**Diagnosis:**
```bash
# Test from pod
kubectl exec -it <pod-name> -n sligo -- sh
# Inside pod:
nc -zv postgres 5432  # For internal DB
nc -zv <rds-host> 5432  # For external DB
```

**Common causes:**

1. **Wrong database host**
   - **Solution:** Verify `database.external.host` in values

2. **Database security group**
   - RDS security group not allowing EKS traffic
   - **Solution:** Add EKS security group to RDS allowed list

3. **Credentials incorrect**
   - **Solution:** Verify secrets have correct values

## Database Issues

### PostgreSQL Not Starting

**Symptom:** PostgreSQL pod not starting

**Diagnosis:**
```bash
kubectl logs postgres-0 -n sligo
kubectl describe statefulset postgres -n sligo
```

**Common causes:**

1. **PVC not bound**
   - Check: `kubectl get pvc -n sligo`
   - **Solution:** Verify storage class exists

2. **Insufficient resources**
   - **Solution:** Increase resource limits

3. **Data corruption**
   - Last resort: Delete PVC and start fresh (data loss!)

### Cannot Connect to PostgreSQL

**Diagnosis:**
```bash
# From within cluster
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n sligo -- \
  psql -h postgres -U sligo -d sligo

# Check service
kubectl get svc postgres -n sligo
```

## Ingress Issues

### ALB Not Created (AWS)

**Symptom:** No load balancer appears in AWS console

**Diagnosis:**
```bash
# Check ingress events
kubectl describe ingress -n sligo

# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Common causes:**

1. **ALB controller not installed**
   - **Solution:** Install AWS Load Balancer Controller

2. **IAM permissions missing**
   - **Solution:** Attach required IAM policy to node role

3. **Invalid annotations**
   - **Solution:** Check ALB annotations in values

### SSL/TLS Issues

**Symptom:** HTTPS not working or certificate errors

**Common causes:**

1. **Certificate ARN incorrect**
   - **Solution:** Verify ACM certificate ARN in annotations

2. **Certificate not validated**
   - **Solution:** Complete ACM certificate validation

3. **Domain mismatch**
   - Certificate domain doesn't match ingress host
   - **Solution:** Update certificate or ingress host

## Performance Issues

### High CPU Usage

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -n sligo

# Check metrics
kubectl describe pod <pod-name> -n sligo | grep -A 10 "Limits"
```

**Solutions:**

1. **Increase resource limits**
```yaml
app:
  resources:
    limits:
      cpu: 2000m  # Increase from 500m
```

2. **Scale horizontally**
```yaml
app:
  replicaCount: 5  # Increase from 2
```

3. **Enable autoscaling**
```yaml
app:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
```

### High Memory Usage

**Solutions:**

1. **Increase memory limits**
```yaml
app:
  resources:
    limits:
      memory: 2Gi  # Increase from 512Mi
```

2. **Check for memory leaks**
   - Review application logs
   - Monitor over time

### Slow Response Times

**Common causes:**

1. **Database queries slow**
   - **Solution:** Add database indexes
   - **Solution:** Enable connection pooling

2. **Insufficient resources**
   - **Solution:** Increase CPU/memory limits

3. **Too few replicas**
   - **Solution:** Scale up or enable autoscaling

## Getting Help

If you're still experiencing issues:

**Gather information:**
```bash
# Get all resources
kubectl get all -n sligo

# Get events
kubectl get events -n sligo --sort-by='.lastTimestamp'

# Get logs from all pods
kubectl logs -n sligo -l app.kubernetes.io/name=sligo-cloud --tail=100
```

**Contact support:**
- Email: support@sligo.ai
- Include:
  - Helm chart version
  - Kubernetes version
  - AWS region (if applicable)
  - Error messages and logs
  - Steps to reproduce

**Community resources:**
- GitHub Issues: https://github.com/Sligo-AI/sligo-helm-charts/issues
- Documentation: https://sligo-ai.github.io/sligo-helm-charts
