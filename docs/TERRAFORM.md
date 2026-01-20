# Terraform/IAC Integration

This guide shows how to deploy Sligo Cloud using Infrastructure as Code (IAC) with Terraform.

## Prerequisites

- Terraform 1.0+ installed
- `helm` version 3.10+ installed (for Terraform Helm provider)
- Kubernetes cluster access (`kubectl` configured)
- Access to provision infrastructure (AWS/GCP credentials)

## Overview

Using Terraform allows you to:
- Manage infrastructure and application deployment in code
- Version control both infrastructure and application configuration
- Deploy everything with a single `terraform apply`
- Automate infrastructure lifecycle management

## Architecture

With Terraform, you can provision:
1. **Kubernetes cluster** (EKS for AWS, GKE for GCP)
2. **Database** (RDS for AWS, Cloud SQL for GCP, or in-cluster)
3. **Cache** (ElastiCache for AWS, Memorystore for GCP, or in-cluster)
4. **Helm Chart deployment** (Sligo Cloud application)

All in one Terraform configuration.

## Terraform Providers Required

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # For GCP
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

## Example: AWS EKS Deployment

### 1. Provider Configuration

```hcl
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}
```

### 2. Infrastructure Provisioning

```hcl
# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # ... other EKS configuration
}

# RDS Database (if using external database)
resource "aws_db_instance" "postgres" {
  identifier     = "sligo-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 100
  storage_encrypted     = true
  
  db_name  = "sligo"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  skip_final_snapshot    = false
}

# ElastiCache Redis (if using external Redis)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "sligo-redis"
  description                = "Sligo Redis cache"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  
  port                        = 6379
  parameter_group_name        = "default.redis7"
  
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled  = true
}
```

### 3. Kubernetes Namespace

```hcl
resource "kubernetes_namespace" "sligo" {
  metadata {
    name = "sligo"
  }
}
```

### 4. Create Secrets

```hcl
# Image pull secret (from service account key provided by Sligo)
resource "kubernetes_secret" "registry_credentials" {
  metadata {
    name      = "sligo-registry-credentials"
    namespace = kubernetes_namespace.sligo.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "us-central1-docker.pkg.dev" = {
          username = "_json_key"
          password = file(var.sligo_service_account_key_path)
          auth     = base64encode("_json_key:${file(var.sligo_service_account_key_path)}")
        }
      }
    })
  }
}

# Application secrets
resource "kubernetes_secret" "nextjs_secrets" {
  metadata {
    name      = "nextjs-secrets"
    namespace = kubernetes_namespace.sligo.metadata[0].name
  }

  data = {
    DATABASE_URL = "postgresql://${aws_db_instance.postgres.username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
    NEXTAUTH_SECRET = var.nextauth_secret
    NEXT_PUBLIC_API_URL = var.next_public_api_url
    # ... other required keys
  }
}

# Backend secrets
resource "kubernetes_secret" "backend_secrets" {
  metadata {
    name      = "backend-secrets"
    namespace = kubernetes_namespace.sligo.metadata[0].name
  }

  data = {
    DATABASE_URL = "postgresql://${aws_db_instance.postgres.username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
    REDIS_URL = "redis://${aws_elasticache_replication_group.redis.configuration_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
    JWT_SECRET = var.jwt_secret
    API_KEY = var.api_key
    # ... other required keys
  }
}

# MCP Gateway secrets
resource "kubernetes_secret" "mcp_gateway_secrets" {
  metadata {
    name      = "mcp-gateway-secrets"
    namespace = kubernetes_namespace.sligo.metadata[0].name
  }

  data = {
    GATEWAY_SECRET = var.gateway_secret
    BACKEND_URL = "http://sligo-backend:3001"
    FRONTEND_URL = var.frontend_url
    # ... other required keys
  }
}
```

### 5. Deploy Helm Chart

```hcl
# Add Helm repository
data "helm_repository" "sligo" {
  name = "sligo"
  url  = "https://sligo-ai.github.io/sligo-helm-charts"
}

# Deploy Sligo Cloud Helm chart
resource "helm_release" "sligo_cloud" {
  name       = "sligo-app"
  repository = data.helm_repository.sligo.url
  chart      = "sligo-cloud"
  version    = "1.0.0"
  namespace  = kubernetes_namespace.sligo.metadata[0].name

  depends_on = [
    kubernetes_secret.registry_credentials,
    kubernetes_secret.nextjs_secrets,
    kubernetes_secret.backend_secrets,
    kubernetes_secret.mcp_gateway_secrets
  ]

  # Values from variables or files
  values = [
    templatefile("${path.module}/values-production.yaml", {
      # Terraform variables can be passed to values.yaml
      image_repository = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}"
      domain_name      = var.domain_name
      db_host          = aws_db_instance.postgres.endpoint
      redis_host       = aws_elasticache_replication_group.redis.configuration_endpoint_address
      acm_cert_arn     = aws_acm_certificate.main.arn
    })
  ]

  # Or use set blocks for individual values
  set {
    name  = "global.imagePullSecrets[0]"
    value = kubernetes_secret.registry_credentials.metadata[0].name
  }

  set {
    name  = "app.image.repository"
    value = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}/sligo-web"
  }

  set {
    name  = "app.image.tag"
    value = var.app_version
  }

  set {
    name  = "backend.image.repository"
    value = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}/sligo-api"
  }

  set {
    name  = "mcpGateway.image.repository"
    value = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}/mcp-gateway"
  }

  # Configure external database
  set {
    name  = "database.type"
    value = "external"
  }

  set {
    name  = "database.external.host"
    value = aws_db_instance.postgres.endpoint
  }

  # Configure external Redis
  set {
    name  = "redis.type"
    value = "external"
  }

  set {
    name  = "redis.external.host"
    value = aws_elasticache_replication_group.redis.configuration_endpoint_address
  }

  # Ingress configuration for AWS ALB
  set {
    name  = "ingress.className"
    value = "alb"
  }

  set {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = aws_acm_certificate.main.arn
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.domain_name
  }
}
```

### 6. Variables

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for application"
  type        = string
}

variable "client_repository_name" {
  description = "Client-specific GAR repository name (provided by Sligo)"
  type        = string
}

variable "sligo_service_account_key_path" {
  description = "Path to Sligo service account key JSON file"
  type        = string
  sensitive   = true
}

variable "app_version" {
  description = "Sligo Cloud application version"
  type        = string
  default     = "v1.0.0"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key"
  type        = string
  sensitive   = true
}

variable "gateway_secret" {
  description = "MCP Gateway secret"
  type        = string
  sensitive   = true
}

variable "frontend_url" {
  description = "Frontend URL"
  type        = string
}

variable "next_public_api_url" {
  description = "Public API URL"
  type        = string
}
```

### 7. Outputs

```hcl
# outputs.tf
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "ingress_hostname" {
  description = "ALB hostname from ingress"
  value       = helm_release.sligo_cloud.status.ingress[0].hostname
}
```

## Example: GCP GKE Deployment

### 1. Provider Configuration

```hcl
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

data "google_client_config" "provider" {}
```

### 2. Infrastructure Provisioning

```hcl
# GKE Cluster
module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"
  
  project_id        = var.gcp_project_id
  name              = var.cluster_name
  region            = var.gcp_region
  zones             = var.gcp_zones
  
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  
  # ... other GKE configuration
}

# Cloud SQL Database (if using external database)
resource "google_sql_database_instance" "postgres" {
  name             = "sligo-postgres"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  
  settings {
    tier              = "db-f1-micro"
    disk_size         = 100
    disk_type         = "PD_SSD"
    availability_type = "ZONAL"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.vpc.network_id
    }
    
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }
  }
}

resource "google_sql_database" "sligo" {
  name     = "sligo"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "sligo_user" {
  name     = var.db_username
  password = var.db_password
  instance = google_sql_database_instance.postgres.name
}

# Memorystore Redis (if using external Redis)
resource "google_redis_instance" "redis" {
  name           = "sligo-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.gcp_region
  
  authorized_network = module.vpc.network_id
}
```

### 3. Deploy Helm Chart (GCP)

```hcl
resource "helm_release" "sligo_cloud" {
  name       = "sligo-app"
  repository = "https://sligo-ai.github.io/sligo-helm-charts"
  chart      = "sligo-cloud"
  version    = "1.0.0"
  namespace  = kubernetes_namespace.sligo.metadata[0].name

  set {
    name  = "global.imagePullSecrets[0]"
    value = kubernetes_secret.registry_credentials.metadata[0].name
  }

  set {
    name  = "app.image.repository"
    value = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}/sligo-web"
  }

  # Configure external database (Cloud SQL)
  set {
    name  = "database.type"
    value = "external"
  }

  set {
    name  = "database.external.host"
    value = google_sql_database_instance.postgres.private_ip_address
  }

  # Configure external Redis (Memorystore)
  set {
    name  = "redis.type"
    value = "external"
  }

  set {
    name  = "redis.external.host"
    value = google_redis_instance.redis.host
  }

  # Ingress configuration for GCP load balancer
  set {
    name  = "ingress.className"
    value = "gce"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.domain_name
  }
}
```

## Managing Values in Terraform

### Option 1: Template Files

Use `templatefile()` to render values.yaml:

```hcl
# values-production.yaml.tpl
global:
  imagePullSecrets:
    - name: sligo-registry-credentials

app:
  image:
    repository: ${image_repository}/sligo-web
    tag: ${app_version}

ingress:
  hosts:
    - host: ${domain_name}
```

```hcl
resource "helm_release" "sligo_cloud" {
  values = [
    templatefile("${path.module}/values-production.yaml.tpl", {
      image_repository = "us-central1-docker.pkg.dev/sligo-ai-platform/${var.client_repository_name}"
      app_version      = var.app_version
      domain_name      = var.domain_name
    })
  ]
}
```

### Option 2: Set Blocks

Use `set` blocks for individual values:

```hcl
resource "helm_release" "sligo_cloud" {
  set {
    name  = "app.replicaCount"
    value = 3
  }

  set {
    name  = "app.resources.limits.cpu"
    value = "1000m"
  }
}
```

### Option 3: Values Files + Set Blocks

Combine values file with set blocks:

```hcl
resource "helm_release" "sligo_cloud" {
  values = [
    file("${path.module}/values-base.yaml")
  ]

  set {
    name  = "app.image.repository"
    value = var.image_repository
  }
}
```

## Workflow

### Initial Deployment

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply (provisions infrastructure + deploys Helm chart)
terraform apply
```

### Updates

```bash
# Update values
# Edit variables or values files

# Plan changes
terraform plan

# Apply updates
terraform apply
```

### Upgrading Chart Version

```hcl
resource "helm_release" "sligo_cloud" {
  # Change version here
  version = "1.1.0"
  
  # ... rest of configuration
}
```

```bash
terraform apply  # Upgrades Helm release
```

## Next Steps

- Review [INSTALLATION.md](./INSTALLATION.md) for direct Helm CLI approach
- Review [CONFIGURATION.md](./CONFIGURATION.md) for all available values
- Review [SECRETS.md](./SECRETS.md) for required secrets
