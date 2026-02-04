# Sligo Helm Charts

Official Helm charts for deploying Sligo Enterprise Platform.

**Helm Repository:** [https://github.com/Sligo-AI/sligo-helm-charts](https://github.com/Sligo-AI/sligo-helm-charts)
**Helm Page:** [https://sligo-ai.github.io/sligo-helm-charts/](https://sligo-ai.github.io/sligo-helm-charts/)
**Terraform Repository:** [https://github.com/Sligo-AI/sligo-terraform](https://github.com/Sligo-AI/sligo-terraform)



## Installation

### Prerequisites

**⚠️ IMPORTANT: Create Required Secrets Before Installation**

Before installing the Helm chart, you must create Kubernetes secrets containing all required environment variables. The chart expects these secrets to exist:

- **`nextjs-secrets`** - Frontend/Next.js application secrets
- **`backend-secrets`** - Backend API secrets  
- **`mcp-gateway-secrets`** - MCP Gateway secrets
- **`postgres-secrets`** or **`postgres-external-secrets`** - Database credentials (depending on database type)
- **`redis-external-secrets`** - Redis credentials (if using external Redis)

**📖 See [Secrets Setup Guide](docs/SECRETS.md) for complete list of required keys and creation commands.**

Example:
```bash
# Create namespace first
kubectl create namespace sligo

# Create secrets (see SECRETS.md for full command with all keys)
kubectl create secret generic nextjs-secrets \
  --from-literal=BACKEND_URL="https://your-backend-url.com" \
  --from-literal=DATABASE_URL="postgresql://..." \
  # ... (see SECRETS.md for complete list)
  -n sligo
```

### Add Helm Repository

```bash
helm repo add sligo https://sligo-ai.github.io/sligo-helm-charts
helm repo update
```

### Install Chart

```bash
helm install sligo-app sligo/sligo-cloud \
  --version 1.0.0 \
  -f values-production.yaml \
  -n sligo \
  --create-namespace
```

**Note:** The `--create-namespace` flag will create the namespace if it doesn't exist, but secrets must be created manually before or after installation.

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Step-by-step installation instructions
- **[Secrets Setup](docs/SECRETS.md)** ⚠️ **REQUIRED** - Complete list of required environment variables and secret creation commands
- [Configuration Reference](docs/CONFIGURATION.md) - All available configuration options
- [Terraform/IAC Integration](docs/TERRAFORM.md) - Infrastructure as Code setup
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Upgrade Guide](docs/UPGRADE.md) - How to upgrade to new versions

## 📌 Versioning and Image Tags

Sligo Enterprise uses semantic versioning for container images. When deploying, you should pin to specific version tags for production deployments.

### Using Version Tags

**Production deployments** should always pin to a specific version:
```yaml
app:
  image:
    tag: "v1.0.0"  # Pin to specific version

backend:
  image:
    tag: "v1.0.0"  # Pin to specific version

mcpGateway:
  image:
    tag: "v1.0.0"  # Pin to specific version
```

**Development/testing** can use `latest` (not recommended for production):
```yaml
app:
  image:
    tag: "latest"  # Development only
```

### Finding Available Versions

1. **Check Google Artifact Registry:**
   ```bash
   gcloud artifacts docker images list \
     us-central1-docker.pkg.dev/sligo-ai-platform/<your-repository-name>/sligo-backend \
     --format="table(tags)"
   ```

2. **Contact Sligo support** (support@sligo.ai) for a list of available versions

### Upgrading Versions

To upgrade to a new version:

1. Update the `tag` values in your `values.yaml` file
2. Run `helm upgrade`:
   ```bash
   helm upgrade sligo-app sligo/sligo-cloud \
     -f values-production.yaml \
     -n sligo
   ```

**Best Practice:** Test upgrades in a non-production environment first.

## Support

For issues or questions, contact support@sligo.ai
