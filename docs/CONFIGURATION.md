# Configuration Reference

Complete reference for all configuration values in Sligo Cloud Helm chart.

## Table of Contents
- [Global Settings](#global-settings)
- [App Component](#app-component)
- [Backend Component](#backend-component)
- [MCP Gateway Component](#mcp-gateway-component)
- [Database](#database)
- [Redis](#redis)
- [Ingress](#ingress)
- [AWS Settings](#aws-settings)
- [Advanced Settings](#advanced-settings)

---

## Global Settings

```yaml
global:
  # Image pull secrets for Sligo's Google Artifact Registry
  # Reference the Kubernetes secret name (NOT the service account key file itself)
  imagePullSecrets: []
  # imagePullSecrets:
  #   - name: sligo-registry-credentials  # Secret name created in Kubernetes
```

**To create image pull secret:**

Sligo hosts all container images in Google Artifact Registry (GAR), regardless of your cloud provider. Sligo will provide a service account key JSON file for your client-specific repository.

**Step 1:** Create the Kubernetes secret using the service account key file:

```bash
# Use the service account key file provided by Sligo (saved locally)
kubectl create secret docker-registry sligo-registry-credentials \
  --docker-server=us-central1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat /path/to/sligo-service-account-key.json)" \
  -n sligo
```

**Step 2:** Reference the secret name in your values.yaml:
```yaml
global:
  imagePullSecrets:
    - name: sligo-registry-credentials  # Secret name only (not the key file)
```

**Important:** 
- The service account key JSON file is **NOT** added to values.yaml
- Only the secret **name** (`sligo-registry-credentials`) goes in values.yaml
- The secret must exist in Kubernetes before running `helm install`

**Registry details:**
- Project: `sligo-ai-platform`
- Region: `us-central1`
- Repository: `your-client-containers` (client-specific, provided by Sligo)
- Service account: Client-specific service account with access to your repository

**Example image URLs:**
```
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-web:v1.0.0
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/sligo-api:v1.0.0
us-central1-docker.pkg.dev/sligo-ai-platform/your-client-containers/mcp-gateway:v1.0.0
```

**Note:** Contact Sligo support (support@sligo.ai) to get access, exact registry URLs, and your client-specific repository name.

## App Component

Frontend Next.js application.

```yaml
app:
  enabled: true                    # Enable/disable component
  name: sligo-app                  # Service name
  replicaCount: 2                  # Number of pods
  
  image:
    repository: "..."              # Container image repository URL (ECR or GAR)
    tag: "latest"                  # Image tag
    pullPolicy: Always             # Always, IfNotPresent, Never
  
  service:
    type: ClusterIP                # ClusterIP, NodePort, LoadBalancer
    port: 3000                     # Service port
    targetPort: 3000               # Container port
  
  resources:
    requests:
      cpu: 100m                    # Minimum CPU
      memory: 256Mi                # Minimum memory
    limits:
      cpu: 500m                    # Maximum CPU
      memory: 512Mi                # Maximum memory
  
  secretName: nextjs-secrets       # Secret containing env vars
  
  env: {}                          # Additional environment variables
  # env:
  #   NODE_ENV: production
  
  livenessProbe:                   # Health check for restarts
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
  
  readinessProbe:                  # Health check for traffic
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 15
    periodSeconds: 5
```

### Autoscaling (Optional)

```yaml
app:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

## Backend Component

Backend API service.

```yaml
backend:
  enabled: true
  name: sligo-backend
  replicaCount: 2
  
  image:
    repository: "..."
    tag: "latest"
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 3001
    targetPort: 3001
  
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  secretName: backend-secrets
  env: {}
```

## MCP Gateway Component

MCP Gateway service.

```yaml
mcpGateway:
  enabled: true
  name: mcp-gateway
  replicaCount: 2
  
  image:
    repository: "..."
    tag: "latest"
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 3002
    targetPort: 3002
  
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  secretName: mcp-gateway-secrets
  env: {}
```

## Database

PostgreSQL database configuration.

### Internal Database (In-Cluster)

```yaml
database:
  enabled: true
  type: internal                   # Use in-cluster PostgreSQL
  
  internal:
    name: postgres
    image:
      repository: postgres
      tag: "16-alpine"
      pullPolicy: IfNotPresent
    
    service:
      type: ClusterIP
      port: 5432
    
    persistence:
      enabled: true                # Enable persistent storage
      storageClass: "gp3"          # AWS EBS GP3
      size: 20Gi                   # Storage size
      accessMode: ReadWriteOnce
    
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
    
    secretName: postgres-secrets   # POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
```

**Pros:** Simple setup, good for dev/staging  
**Cons:** Requires backup management, less scalable

### External Database (RDS)

```yaml
database:
  enabled: true
  type: external                   # Use external database
  
  external:
    host: "mydb.123.us-east-1.rds.amazonaws.com"
    port: 5432
    database: "sligo_prod"
    secretName: postgres-external-secrets
```

**Pros:** Managed backups, scalable, production-ready  
**Cons:** Additional AWS cost

## Redis

Redis cache configuration.

### Internal Redis (In-Cluster)

```yaml
redis:
  enabled: true
  type: internal
  
  internal:
    name: redis
    image:
      repository: redis
      tag: "7-alpine"
      pullPolicy: IfNotPresent
    
    service:
      type: ClusterIP
      port: 6379
    
    persistence:
      enabled: true
      storageClass: "gp3"
      size: 10Gi
      accessMode: ReadWriteOnce
    
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
    
    secretName: ""                 # Optional password
```

### External Redis (ElastiCache)

```yaml
redis:
  enabled: true
  type: external
  
  external:
    host: "myredis.abc.0001.use1.cache.amazonaws.com"
    port: 6379
    secretName: redis-external-secrets
```

## Ingress

Load balancer and routing configuration.

### AWS ALB

```yaml
ingress:
  enabled: true
  className: alb
  
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123:certificate/xxx
    
    # Optional: WAF
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:us-east-1:123:regional/webacl/prod/xxx
    
    # Optional: Health check
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
  
  hosts:
    - host: app.company.com
      paths:
        - path: /
          pathType: Prefix
          backend: app               # Routes to app service
        - path: /api
          pathType: Prefix
          backend: backend           # Routes to backend service
        - path: /mcp
          pathType: Prefix
          backend: mcpGateway        # Routes to mcp-gateway service
  
  tls: []                            # TLS handled by ACM cert
```

### NGINX Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  
  hosts:
    - host: app.company.com
      paths:
        - path: /
          pathType: Prefix
          backend: app
  
  tls:
    - secretName: app-tls-cert      # Created by cert-manager
      hosts:
        - app.company.com
```

## AWS Settings

```yaml
aws:
  region: us-east-1
  
  storageClass:
    default: gp3                    # GP3, GP2, IO1, etc.
  
  alb:
    enabled: false
    certificateArn: ""
    securityGroups: []
    subnets: []
```

## Advanced Settings

### Node Selectors

Deploy to specific nodes:

```yaml
nodeSelector:
  workload-type: application
  environment: production
```

### Tolerations

Allow scheduling on tainted nodes:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "app"
    effect: "NoSchedule"
```

### Affinity

Pod anti-affinity for high availability:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - sligo-cloud
          topologyKey: kubernetes.io/hostname
```

### Security Context

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: false
```

## Complete Example

See `examples/values-production-aws.yaml` for a complete production configuration.
