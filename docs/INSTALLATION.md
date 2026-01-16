# Sligo Cloud - Installation Guide

## Prerequisites

### Required Tools
- Kubernetes cluster (EKS recommended) version 1.24+
- `kubectl` configured with cluster access
- `helm` version 3.10+

### Required Resources
- ECR access to Sligo container images
- Domain name for application access
- SSL certificate (ACM for AWS)
- Database (RDS PostgreSQL 15+ or in-cluster)
- Cache (ElastiCache Redis 7+ or in-cluster)

### Required Secrets
See [SECRETS.md](./SECRETS.md) for details on required secret values.

## Installation Steps

### 1. Add Helm Repository

```bash
helm repo add sligo https://sligo-ai.github.io/sligo-helm-charts
helm repo update
```

### 2. Create Namespace

```bash
kubectl create namespace sligo
```

### 3. Create Secrets

Create all required secrets before installation:

```bash
# App secrets
kubectl create secret generic nextjs-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=NEXTAUTH_SECRET="your-secret-here" \
  --from-literal=NEXT_PUBLIC_API_URL="https://api.your-domain.com" \
  -n sligo

# Backend secrets
kubectl create secret generic backend-secrets \
  --from-literal=JWT_SECRET="your-jwt-secret" \
  --from-literal=API_KEY="your-api-key" \
  -n sligo

# MCP Gateway secrets
kubectl create secret generic mcp-gateway-secrets \
  --from-literal=GATEWAY_SECRET="your-gateway-secret" \
  -n sligo

# Database credentials (if using external)
kubectl create secret generic postgres-external-secrets \
  --from-literal=POSTGRES_USER="sligo_user" \
  --from-literal=POSTGRES_PASSWORD="secure-password" \
  --from-literal=POSTGRES_DB="sligo" \
  -n sligo

# Redis password (if using external)
kubectl create secret generic redis-external-secrets \
  --from-literal=REDIS_PASSWORD="secure-password" \
  -n sligo
```

See [SECRETS.md](./SECRETS.md) for complete list of required keys.

### 4. Customize Values

Copy the template and customize:

```bash
cp examples/values-client-template.yaml values-production.yaml
```

Edit `values-production.yaml` with your specific configuration:
- Update ECR repository URLs
- Configure domain names
- Set resource limits
- Configure database connection
- Add ACM certificate ARN

### 5. Install Chart

```bash
helm install sligo-app sligo/sligo-cloud \
  --version 1.0.0 \
  -f values-production.yaml \
  -n sligo
```

### 6. Verify Installation

```bash
# Check pods
kubectl get pods -n sligo

# Check services
kubectl get svc -n sligo

# Check ingress
kubectl get ingress -n sligo

# Get load balancer URL (AWS ALB)
kubectl get ingress -n sligo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### 7. Configure DNS

Point your domain to the load balancer:

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress -n sligo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
echo "Create CNAME record: app.your-domain.com -> $ALB_DNS"
```

### 8. Test Application

```bash
# Test health endpoint
curl https://app.your-domain.com/api/health

# Check logs
kubectl logs -n sligo -l app.kubernetes.io/component=app --tail=50
```

## Post-Installation

### Enable Monitoring (Optional)

If you have Prometheus/Grafana:

```bash
# Add service monitors
kubectl apply -f monitoring/service-monitors.yaml -n sligo
```

### Configure Backups

For in-cluster database:

```bash
# Set up backup cronjob
kubectl apply -f backup/postgres-backup.yaml -n sligo
```

### Configure Auto-scaling (Optional)

In `values.yaml`:

```yaml
app:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

## Troubleshooting

If pods are not starting:

```bash
# Check pod status
kubectl describe pod <pod-name> -n sligo

# Check logs
kubectl logs <pod-name> -n sligo

# Check secrets
kubectl get secrets -n sligo
```

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues.

## Next Steps

- Review [CONFIGURATION.md](./CONFIGURATION.md) for advanced options
- Set up monitoring and alerting
- Configure backups
- Review [UPGRADE.md](./UPGRADE.md) for upgrade procedures
