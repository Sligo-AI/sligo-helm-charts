---
layout: home
permalink: /
title: "Sligo Enterprise - Helm Charts"
description: "Official Helm charts for deploying Sligo Enterprise Platform."
hero_actions:
  - label: "Installation Guide"
    url: "/INSTALLATION/"
    style: "primary"
    icon: true
  - label: "View on GitHub"
    url: "https://github.com/Sligo-AI/sligo-helm-charts"
    style: "outline"
features:
  - title: "Production Ready"
    description: "Battle-tested Helm charts for enterprise Kubernetes deployments."
    icon: "server"
  - title: "Comprehensive Docs"
    description: "Configuration reference, secrets setup, and troubleshooting guides."
    icon: "book"
  - title: "Terraform Integration"
    description: "Deploy with our Terraform modules for full infrastructure as code."
    icon: "cloud"
---

## Add the Helm repository

```bash
helm repo add sligo https://sligo-ai.github.io/sligo-helm-charts
helm repo update
```

## Quick install

```bash
helm install sligo-app sligo/sligo-cloud \
  --version 1.0.0 \
  -f values-production.yaml \
  -n sligo \
  --create-namespace
```

**Required:** Create Kubernetes secrets before installing. See the [Secrets Setup](SECRETS/) guide.

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](INSTALLATION/) | Step-by-step installation |
| [Secrets Setup](SECRETS/) | **Required** — Create secrets before install |
| [Configuration Reference](CONFIGURATION/) | All configuration options |
| [Terraform Integration](TERRAFORM/) | Deploy with Terraform |
| [Troubleshooting](TROUBLESHOOTING/) | Common issues and solutions |
| [Upgrade Guide](UPGRADE/) | How to upgrade |

## Support

- **Email:** support@sligo.ai
- **Issues:** [GitHub Issues](https://github.com/Sligo-AI/sligo-helm-charts/issues)
