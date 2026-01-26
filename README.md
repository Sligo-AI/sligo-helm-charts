# Sligo Helm Charts

Official Helm charts for deploying Sligo Cloud Platform.

**Helm Repository:** [https://github.com/Sligo-AI/sligo-helm-charts](https://github.com/Sligo-AI/sligo-helm-charts)
**Helm Page:** [https://sligo-ai.github.io/sligo-helm-charts/](https://sligo-ai.github.io/sligo-helm-charts/)
**Terraform Repository:** [https://github.com/Sligo-AI/sligo-terraform](https://github.com/Sligo-AI/sligo-terraform)



## Installation

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

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Terraform/IAC Integration](docs/TERRAFORM.md)
- [Configuration Reference](docs/CONFIGURATION.md)
- [Secrets Setup](docs/SECRETS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Upgrade Guide](docs/UPGRADE.md)

## 📌 Versioning and Image Tags

Sligo Cloud uses semantic versioning for container images. When deploying, you should pin to specific version tags for production deployments.

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
