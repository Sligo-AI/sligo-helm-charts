# Sligo Cloud - Installation Guide

## Prerequisites

### Required Tools
- Kubernetes cluster (EKS recommended) version 1.24+
- `kubectl` configured with cluster access
- `helm` version 3.10+

### Required Resources
- Container image access to Sligo's Google Artifact Registry (GAR)
- Domain name for application access
- SSL certificate (ACM for AWS, or cert-manager for GCP/on-prem)
- Database (RDS PostgreSQL 15+ for AWS, Cloud SQL for GCP, or in-cluster)
- Cache (ElastiCache Redis 7+ for AWS, Memorystore for GCP, or in-cluster)

### Required Secrets
See [SECRETS.md](./SECRETS.md) for details on required secret values.

## Installation Steps

### 0. Get Container Image Access (Contact Sligo Support)

Sligo hosts all container images in Google Artifact Registry (GAR), regardless of your cloud provider.

**Registry details:**
- **Project**: `sligo-ai-platform`
- **Repository**: Client-specific (`[your-client-name]-containers`)
- **Region**: `us-central1`

**Contact Sligo support** (support@sligo.ai) to:
- Request access to pull container images
- Receive a service account key for your client-specific repository
- Get your exact repository name and image URLs

**After receiving access, create image pull secret:**

1. **Save the service account key file** provided by Sligo (e.g., `sligo-service-account-key.json`)
   - Store this file securely on your local machine
   - **DO NOT commit this file to Git** - it contains credentials

2. **Create Kubernetes secret** using the service account key:
   ```bash
   kubectl create secret docker-registry sligo-registry-credentials \
     --docker-server=us-central1-docker.pkg.dev \
     --docker-username=_json_key \
     --docker-password="$(cat /path/to/sligo-service-account-key.json)" \
     -n sligo
   ```
   This creates a Kubernetes secret in your cluster that will be used to authenticate to GAR when pulling images.

3. **Reference the secret name in values.yaml** (see Step 4):
   - Only the secret **name** (`sligo-registry-credentials`) goes in your values file
   - The service account key file itself is **NOT** added to values.yaml
   - The secret stores the credentials in Kubernetes

**Example GAR image URLs:**
```
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-web:v1.0.0
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-api:v1.0.0
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/mcp-gateway:v1.0.0
```

Replace `your-client-containers` with your actual repository name provided by Sligo.

**Important:** The service account key file is only used **once** to create the Kubernetes secret. After that, Kubernetes uses the secret to authenticate when pulling images during pod startup.

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

**Required:**
- Update container image repository URLs (get from Sligo support - GAR)
- Configure `global.imagePullSecrets` to reference the secret name created in Step 0
  - Use the secret **name** only (e.g., `sligo-registry-credentials`)
  - The service account key file itself is NOT added here
- Configure domain names
- Set resource limits
- Configure database connection
- Add SSL certificate (ACM ARN for AWS, or cert-manager configuration for GCP)

**Example configuration:**
```yaml
global:
  # Reference the Kubernetes secret name (created in Step 0 using kubectl)
  # The service account key file itself is NOT added here - only the secret name
  imagePullSecrets:
    - name: sligo-registry-credentials  # Secret name created in Kubernetes

app:
  image:
    repository: us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-web
    tag: "v1.0.0"

backend:
  image:
    repository: us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-api
    tag: "v1.0.0"

mcpGateway:
  image:
    repository: us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/mcp-gateway
    tag: "v1.0.0"
```

**Note:** 
- All containers are hosted in Sligo's Google Artifact Registry, regardless of your cloud provider (AWS or GCP)
- Replace `your-client-containers` with your actual client-specific repository name provided by Sligo support

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

# Get load balancer URL (AWS ALB or GCP load balancer)
kubectl get ingress -n sligo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### 7. Configure DNS

Point your domain to the load balancer:

```bash
# Get load balancer DNS name (ALB for AWS, or GCP load balancer IP/hostname)
LB_HOST=$(kubectl get ingress -n sligo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
echo "Create CNAME record: app.your-domain.com -> $LB_HOST"
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

- Review [TERRAFORM.md](./TERRAFORM.md) for Infrastructure as Code (IAC) deployment using Terraform
- Review [CONFIGURATION.md](./CONFIGURATION.md) for advanced options
- Set up monitoring and alerting
- Configure backups
- Review [UPGRADE.md](./UPGRADE.md) for upgrade procedures
