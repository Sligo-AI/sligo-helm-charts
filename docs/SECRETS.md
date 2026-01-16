# Required Secrets

This document lists all secrets required for Sligo Cloud deployment.

## Secret Creation Methods

### Option 1: kubectl create secret (Recommended)

```bash
kubectl create secret generic <secret-name> \
  --from-literal=KEY1=value1 \
  --from-literal=KEY2=value2 \
  -n sligo
```

### Option 2: From Environment File

```bash
# Create .env file
cat > secrets.env << EOF
KEY1=value1
KEY2=value2
EOF

# Create secret
kubectl create secret generic <secret-name> \
  --from-env-file=secrets.env \
  -n sligo

# Remove env file
rm secrets.env
```

### Option 3: AWS Secrets Manager (Advanced)

Use External Secrets Operator to sync from AWS Secrets Manager.

## Required Secrets

### 1. nextjs-secrets

Application frontend secrets.

**Required Keys:**
- `DATABASE_URL=postgresql://user:password@host:5432/database`
- `NEXTAUTH_URL=https://app.your-domain.com`
- `NEXTAUTH_SECRET=<generate with: openssl rand -base64 32>`
- `NEXT_PUBLIC_API_URL=https://api.your-domain.com`

**Optional Keys:**
- `SMTP_HOST=smtp.example.com`
- `SMTP_PORT=587`
- `SMTP_USER=noreply@your-domain.com`
- `SMTP_PASSWORD=smtp-password`
- `GOOGLE_CLIENT_ID=your-google-oauth-id`
- `GOOGLE_CLIENT_SECRET=your-google-oauth-secret`

**Creation:**
```bash
kubectl create secret generic nextjs-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=NEXTAUTH_URL="https://app.your-domain.com" \
  --from-literal=NEXTAUTH_SECRET="$(openssl rand -base64 32)" \
  --from-literal=NEXT_PUBLIC_API_URL="https://api.your-domain.com" \
  -n sligo
```

### 2. backend-secrets

Backend API secrets.

**Required Keys:**
- `DATABASE_URL=postgresql://user:password@host:5432/database`
- `JWT_SECRET=<generate with: openssl rand -base64 32>`
- `API_KEY=<your-api-key>`

**Optional Keys:**
- `AWS_ACCESS_KEY_ID=AKIA...`
- `AWS_SECRET_ACCESS_KEY=...`
- `AWS_REGION=us-east-1`
- `S3_BUCKET=your-bucket-name`
- `REDIS_URL=redis://redis:6379`

**Creation:**
```bash
kubectl create secret generic backend-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=JWT_SECRET="$(openssl rand -base64 32)" \
  --from-literal=API_KEY="your-api-key-here" \
  -n sligo
```

### 3. mcp-gateway-secrets

MCP Gateway secrets.

**Required Keys:**
- `GATEWAY_SECRET=<generate with: openssl rand -base64 32>`
- `BACKEND_URL=http://sligo-backend:3001`

**Creation:**
```bash
kubectl create secret generic mcp-gateway-secrets \
  --from-literal=GATEWAY_SECRET="$(openssl rand -base64 32)" \
  --from-literal=BACKEND_URL="http://sligo-backend:3001" \
  -n sligo
```

### 4. postgres-secrets (Internal Database)

Only required if using `database.type: internal`

**Required Keys:**
- `POSTGRES_USER=sligo`
- `POSTGRES_PASSWORD=<secure-password>`
- `POSTGRES_DB=sligo`

**Creation:**
```bash
kubectl create secret generic postgres-secrets \
  --from-literal=POSTGRES_USER="sligo" \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 32)" \
  --from-literal=POSTGRES_DB="sligo" \
  -n sligo
```

### 5. postgres-external-secrets (External Database)

Only required if using `database.type: external`

**Required Keys:**
- `POSTGRES_USER=sligo_prod`
- `POSTGRES_PASSWORD=<rds-password>`
- `POSTGRES_DB=sligo_prod`
- `POSTGRES_HOST=<set in values.yaml>`
- `POSTGRES_PORT=5432`

**Creation:**
```bash
kubectl create secret generic postgres-external-secrets \
  --from-literal=POSTGRES_USER="sligo_prod" \
  --from-literal=POSTGRES_PASSWORD="your-rds-password" \
  --from-literal=POSTGRES_DB="sligo_prod" \
  -n sligo
```

### 6. redis-external-secrets (External Redis)

Only required if using `redis.type: external`

**Required Keys:**
- `REDIS_PASSWORD=<elasticache-auth-token>`
- `REDIS_HOST=<set in values.yaml>`
- `REDIS_PORT=6379`

**Creation:**
```bash
kubectl create secret generic redis-external-secrets \
  --from-literal=REDIS_PASSWORD="your-elasticache-token" \
  -n sligo
```

## Security Best Practices

- **Never commit secrets to Git** - Add `*.env` to `.gitignore`
- **Use secrets management tools** - AWS Secrets Manager, HashiCorp Vault
- **Rotate secrets regularly**
  - Database passwords every 90 days
  - API keys every 180 days
  - JWT secrets yearly
- **Use AWS Secrets Manager for production**
  - Automatic rotation
  - Audit logging
  - Integration with EKS
- **Encrypt secrets at rest**
  - Enable EKS encryption
  - Use encrypted etcd
- **Limit secret access**
  - Use RBAC to restrict access
  - Only grant to necessary service accounts

## Validation

Verify secrets are created:

```bash
# List all secrets
kubectl get secrets -n sligo

# Describe secret (doesn't show values)
kubectl describe secret nextjs-secrets -n sligo

# Decode secret value (careful!)
kubectl get secret nextjs-secrets -n sligo -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

## Updating Secrets

To update a secret:

```bash
# Delete old secret
kubectl delete secret nextjs-secrets -n sligo

# Create new secret
kubectl create secret generic nextjs-secrets \
  --from-literal=... \
  -n sligo

# Restart pods to pick up new secret
kubectl rollout restart deployment/sligo-app -n sligo
```
