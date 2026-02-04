---
layout: page
title: "Upgrade Guide"
description: "How to upgrade Sligo Enterprise to a new version."
---

## Before Upgrading

### 1. Check Release Notes

Review release notes for:
- Breaking changes
- New features
- Migration steps required
- Deprecated features

### 2. Backup

**For in-cluster database:**
```bash
# Backup PostgreSQL
kubectl exec postgres-0 -n sligo -- pg_dump -U sligo sligo > backup-$(date +%Y%m%d).sql
```

**For external database (RDS):**
- Take RDS snapshot via AWS console

### 3. Review Current Configuration

```bash
# Get current values
helm get values sligo-app -n sligo > current-values.yaml

# Check current version
helm list -n sligo
```

## Standard Upgrade Process

### 1. Update Helm Repository

```bash
helm repo update sligo
```

### 2. Check Available Versions

```bash
helm search repo sligo/sligo-cloud --versions
```

### 3. Review Changes

```bash
# See what will change
helm diff upgrade sligo-app sligo/sligo-cloud \
  --version NEW_VERSION \
  -f values-production.yaml \
  -n sligo
```

### 4. Perform Upgrade

```bash
helm upgrade sligo-app sligo/sligo-cloud \
  --version NEW_VERSION \
  -f values-production.yaml \
  -n sligo \
  --timeout 10m
```

### 5. Verify Upgrade

```bash
# Check rollout status
kubectl rollout status deployment/sligo-app -n sligo
kubectl rollout status deployment/sligo-backend -n sligo
kubectl rollout status deployment/mcp-gateway -n sligo

# Check pods
kubectl get pods -n sligo

# Check application health
curl https://app.your-domain.com/api/health
```

## Rollback

If upgrade fails or causes issues:

```bash
# Rollback to previous version
helm rollback sligo-app -n sligo

# Or rollback to specific revision
helm rollback sligo-app 1 -n sligo

# Check history
helm history sligo-app -n sligo
```

## Version-Specific Upgrade Notes

### Upgrading to 1.1.0 from 1.0.x

**Changes:**
- Added autoscaling support
- New ingress annotations for AWS ALB

**Migration steps:**
- Review new autoscaling values
- Update ALB annotations if using AWS
- No breaking changes

### Upgrading to 2.0.0 from 1.x.x

**Breaking changes:**
- Secrets structure changed
- Database configuration restructured

**Migration steps:**

1. **Update secrets:**
```bash
# Old format (deprecated)
kubectl delete secret app-secrets -n sligo

# New format
kubectl create secret generic nextjs-secrets \
  --from-literal=DATABASE_URL="..." \
  ...
```

2. **Update values.yaml:**
```yaml
# Old format
database:
  host: postgres

# New format
database:
  type: internal
  internal:
    name: postgres
```

3. **Perform upgrade**

## Zero-Downtime Upgrades

For production systems requiring zero downtime:

### 1. Use Rolling Updates (Default)

Helm automatically performs rolling updates:

```yaml
# In values.yaml
app:
  replicaCount: 3  # Must be > 1 for zero downtime
```

### 2. Blue-Green Deployment (Advanced)

```bash
# Install new version with different release name
helm install sligo-app-v2 sligo/sligo-cloud \
  --version NEW_VERSION \
  -f values-production.yaml \
  -n sligo

# Switch traffic via ingress update
# Then remove old version:
helm uninstall sligo-app -n sligo
```

### 3. Canary Deployment (Advanced)

Use tools like Flagger or Argo Rollouts for gradual traffic shifting.

## Database Migrations

If upgrade includes database schema changes:

### 1. Pre-Upgrade Migration

```bash
# Run migration job before upgrade
kubectl apply -f migration-job.yaml -n sligo

# Wait for completion
kubectl wait --for=condition=complete job/db-migration -n sligo --timeout=300s
```

### 2. Post-Upgrade Verification

```bash
# Verify database schema
kubectl exec -it postgres-0 -n sligo -- psql -U sligo -d sligo -c "\dt"
```

## Configuration Updates

### Adding New Features

```yaml
# In values-production.yaml

# Enable autoscaling
app:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
```

Apply changes:

```bash
helm upgrade sligo-app sligo/sligo-cloud \
  -f values-production.yaml \
  -n sligo
```

### Updating Resource Limits

```yaml
app:
  resources:
    limits:
      cpu: 1000m  # Updated from 500m
      memory: 1Gi  # Updated from 512Mi
```

### Updating Image Tags

To upgrade to a new application version:

1. **Check available versions** in Google Artifact Registry or contact Sligo support
2. **Update image tags** in your `values.yaml`:
   ```yaml
   app:
     image:
       tag: "v1.2.0"  # Updated from v1.1.0
   
   backend:
     image:
       tag: "v1.2.0"  # Updated from v1.1.0
   
   mcpGateway:
     image:
       tag: "v1.2.0"  # Updated from v1.1.0
   ```
3. **Apply the upgrade:**
   ```bash
   helm upgrade sligo-app sligo/sligo-cloud \
     -f values-production.yaml \
     -n sligo
   ```

**Important:** Always use version tags (e.g., `v1.0.0`, `v1.2.3`) in production. Avoid using `latest` as it can cause unexpected updates.

## Troubleshooting Upgrades

### Upgrade Stuck

```bash
# Check status
helm status sligo-app -n sligo

# Check pods
kubectl get pods -n sligo -w

# Check events
kubectl get events -n sligo --sort-by='.lastTimestamp'
```

### Rollback Failed

If automatic rollback fails:

```bash
# Force delete stuck resources
kubectl delete pod <stuck-pod> -n sligo --grace-period=0 --force

# Manual rollback
helm rollback sligo-app -n sligo --force
```

### Configuration Errors

```bash
# Validate new values
helm template test sligo/sligo-cloud \
  -f values-production.yaml \
  --debug

# Check differences
helm diff upgrade sligo-app sligo/sligo-cloud \
  -f values-production.yaml \
  -n sligo
```

## Best Practices

- **Always test upgrades in staging first**
- **Backup before upgrading**
- **Review release notes for breaking changes**
- **Monitor application after upgrade**
- **Keep old backups for at least 30 days**
- **Document any customizations made**
- **Use version pinning in production**

```yaml
# In values-production.yaml
app:
  image:
    tag: "v1.2.0"  # Pin specific version, not "latest"
```

## Scheduled Maintenance

Plan upgrades during low-traffic periods:

- Notify users of maintenance window
- Prepare rollback plan
- Have support team on standby
- Monitor metrics during and after upgrade
- Keep communication channels open

## Support

For upgrade assistance:
- Email: support@sligo.ai
- Include: Current version, target version, error messages
