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

## Support

For issues or questions, contact support@sligo.ai
