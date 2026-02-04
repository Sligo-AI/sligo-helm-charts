---
layout: page
title: "Secrets Setup"
description: "Required Kubernetes secrets and environment variables for Sligo Enterprise deployment."
---

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

> **Note:** Variables marked as "Optional" can be omitted from the secret if not needed. The application will use default values or function without them. However, some optional variables may be required for specific features to work (e.g., LLM API keys for AI features).

### 1. nextjs-secrets

Application frontend secrets.

**Required Keys:**
- `BACKEND_URL=https://your-backend-url.com`
- `DATABASE_URL=postgresql://user:password@host:5432/database`
- `ENCRYPTION_KEY=<generate with: openssl rand -base64 32>`
- `MCP_GATEWAY_URL=http://mcp-gateway:3002` (or external URL)
- `NEXT_PUBLIC_URL=https://app.your-domain.com`
- `NODE_ENV=production` (or `development`)
- `PINECONE_API_KEY=your_pinecone_api_key`
- `PINECONE_INDEX=your_pinecone_index`
- `PORT=3000`
- `WORKOS_API_KEY=your_workos_api_key`
- `WORKOS_CLIENT_ID=your_workos_client_id`
- `WORKOS_COOKIE_PASSWORD=<generate with: openssl rand -base64 32>`
- `NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id`
- `NEXT_PUBLIC_GOOGLE_CLIENT_KEY=your_google_client_key`
- `NEXT_PUBLIC_ONEDRIVE_CLIENT_ID=your_onedrive_client_id`
- `GOOGLE_CLIENT_SECRET=your_google_client_secret`
- `ONEDRIVE_CLIENT_SECRET=your_onedrive_client_secret`
- `REDIS_URL=redis://redis:6379` (or external Redis URL)
- `BUCKET_NAME_AGENT_AVATARS=your_avatars_bucket`
- `BUCKET_NAME_FILE_MANAGER=your_storage_bucket`
- `BUCKET_NAME_LOGOS=your_logos_bucket`
- `BUCKET_NAME_RAG=your_rag_bucket`
- `OPENAI_API_KEY=sk-...`

**Optional Keys:**
- `GOOGLE_PROJECTID=your_google_project_id` (optional, but recommended)
- **Storage Credentials (choose one):**
  - **GCS (Google Cloud Storage):**
    - `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
    - `RAG_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
  - **AWS S3:**
    - `AWS_ACCESS_KEY_ID=your_aws_access_key_id` (optional)
    - `AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key` (optional)
    - `AWS_REGION=us-east-1` (optional, defaults to us-east-1)
    - `AWS_ENDPOINT=https://s3.amazonaws.com` (optional, for S3-compatible services)
  
  > **Note:** You must provide either GCP credentials (`GCP_SA_KEY`/`RAG_SA_KEY`) OR AWS credentials (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), but not both. The application will auto-detect the provider based on available credentials.

**Creation:**
```bash
kubectl create secret generic nextjs-secrets \
  --from-literal=BACKEND_URL="https://your-backend-url.com" \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -base64 32)" \
  --from-literal=MCP_GATEWAY_URL="http://mcp-gateway:3002" \
  --from-literal=NEXT_PUBLIC_URL="https://app.your-domain.com" \
  --from-literal=NODE_ENV="production" \
  --from-literal=PINECONE_API_KEY="your_pinecone_api_key" \
  --from-literal=PINECONE_INDEX="your_pinecone_index" \
  --from-literal=PORT="3000" \
  --from-literal=WORKOS_API_KEY="your_workos_api_key" \
  --from-literal=WORKOS_CLIENT_ID="your_workos_client_id" \
  --from-literal=WORKOS_COOKIE_PASSWORD="$(openssl rand -base64 32)" \
  --from-literal=NEXT_PUBLIC_GOOGLE_CLIENT_ID="your_google_client_id" \
  --from-literal=NEXT_PUBLIC_GOOGLE_CLIENT_KEY="your_google_client_key" \
  --from-literal=NEXT_PUBLIC_ONEDRIVE_CLIENT_ID="your_onedrive_client_id" \
  --from-literal=GOOGLE_CLIENT_SECRET="your_google_client_secret" \
  --from-literal=ONEDRIVE_CLIENT_SECRET="your_onedrive_client_secret" \
  --from-literal=REDIS_URL="redis://redis:6379" \
  --from-literal=BUCKET_NAME_AGENT_AVATARS="your_avatars_bucket" \
  --from-literal=BUCKET_NAME_FILE_MANAGER="your_storage_bucket" \
  --from-literal=BUCKET_NAME_LOGOS="your_logos_bucket" \
  --from-literal=BUCKET_NAME_RAG="your_rag_bucket" \
  --from-literal=OPENAI_API_KEY="sk-..." \
  --from-literal=GOOGLE_PROJECTID="your_google_project_id" \
  # Storage credentials (choose GCS OR AWS, not both):
  # For GCS:
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  --from-literal=RAG_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3:
  # --from-literal=AWS_ACCESS_KEY_ID="your_aws_access_key_id" \
  # --from-literal=AWS_SECRET_ACCESS_KEY="your_aws_secret_access_key" \
  # --from-literal=AWS_REGION="us-east-1" \
  # --from-literal=AWS_ENDPOINT="https://s3.amazonaws.com" \
  -n sligo
```

### 2. backend-secrets

Backend API secrets.

**Required Keys:**
- `NODE_ENV=production` (or `development`)
- `PORT=3001`
- `GOOGLE_PROJECTID=your_google_project_id`
- `MCP_GATEWAY_URL=http://mcp-gateway:3002` (or external URL)
- `DATABASE_URL=postgresql://user:password@host:5432/database`
- `ENCRYPTION_KEY=<generate with: openssl rand -base64 32>`
- `REDIS_URL=redis://redis:6379` (or external Redis URL)
- `BUCKET_NAME_FILE_MANAGER=your_storage_bucket`
- `OPENAI_API_KEY=sk-...`

**Optional Keys:**
- `VERBOSE_LOGGING=true` (or `false`, defaults to `true`)
- `BACKEND_REQUEST_TIMEOUT_MS=300000` (defaults to 300000 if not set)
- **Storage Credentials (choose one):**
  - **GCS (Google Cloud Storage):**
    - `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
  - **AWS S3:**
    - `AWS_ACCESS_KEY_ID=your_aws_access_key_id` (optional)
    - `AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key` (optional)
    - `AWS_REGION=us-east-1` (optional, defaults to us-east-1)
    - `AWS_ENDPOINT=https://s3.amazonaws.com` (optional, for S3-compatible services)
  
  > **Note:** You must provide either GCP credentials (`GCP_SA_KEY`) OR AWS credentials (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), but not both. The application will auto-detect the provider based on available credentials.
- `ANTHROPIC_API_KEY=sk-ant-...` (optional)
- `GOOGLE_VERTEX_AI_WEB_CREDENTIALS={"type":"service_account","project_id":"..."}` (JSON string, optional)
- `OPENAI_BASE_URL=https://api.openai.com/v1` (defaults to `https://api.openai.com/v1` if not set)
- `LANGSMITH_API_KEY=your_langsmith_api_key` (optional)

**Creation:**
```bash
kubectl create secret generic backend-secrets \
  --from-literal=NODE_ENV="production" \
  --from-literal=PORT="3001" \
  --from-literal=GOOGLE_PROJECTID="your_google_project_id" \
  --from-literal=MCP_GATEWAY_URL="http://mcp-gateway:3002" \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -base64 32)" \
  --from-literal=REDIS_URL="redis://redis:6379" \
  --from-literal=BUCKET_NAME_FILE_MANAGER="your_storage_bucket" \
  --from-literal=OPENAI_API_KEY="sk-..." \
  --from-literal=VERBOSE_LOGGING="false" \
  --from-literal=BACKEND_REQUEST_TIMEOUT_MS="300000" \
  # Storage credentials (choose GCS OR AWS, not both):
  # For GCS:
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3:
  # --from-literal=AWS_ACCESS_KEY_ID="your_aws_access_key_id" \
  # --from-literal=AWS_SECRET_ACCESS_KEY="your_aws_secret_access_key" \
  # --from-literal=AWS_REGION="us-east-1" \
  # --from-literal=AWS_ENDPOINT="https://s3.amazonaws.com" \
  --from-literal=ANTHROPIC_API_KEY="sk-ant-..." \
  --from-literal=GOOGLE_VERTEX_AI_WEB_CREDENTIALS='{"type":"service_account","project_id":"..."}' \
  --from-literal=OPENAI_BASE_URL="https://api.openai.com/v1" \
  --from-literal=LANGSMITH_API_KEY="your_langsmith_api_key" \
  -n sligo
```

### 3. mcp-gateway-secrets

MCP Gateway secrets.

**Required Keys:**
- `PORT=3002`
- `FRONTEND_URL=https://app.your-domain.com`
- `PINECONE_API_KEY=your_pinecone_api_key`
- `PINECONE_INDEX=your_pinecone_index`
- `REDIS_URL=redis://redis:6379` (or external Redis URL)
- `BUCKET_NAME_FILE_MANAGER=your_storage_bucket`
- `SPENDHQ_BASE_URL=https://your-spendhq-url.com`
- `SPENDHQ_CLIENT_ID=your_spendhq_client_id`
- `SPENDHQ_CLIENT_SECRET=your_spendhq_client_secret`
- `SPENDHQ_TOKEN_URL=https://your-spendhq-token-url.com`
- `SPENDHQ_SS_HOST=your_singlestore_host`
- `SPENDHQ_SS_USERNAME=your_singlestore_username`
- `SPENDHQ_SS_PASSWORD=your_singlestore_password`
- `SPENDHQ_SS_PORT=3306`

**Optional Keys:**
- `GOOGLE_PROJECTID=your_google_project_id` (optional)
- **Storage Credentials (choose one):**
  - **GCS (Google Cloud Storage):**
    - `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
  - **AWS S3:**
    - `AWS_ACCESS_KEY_ID=your_aws_access_key_id` (optional)
    - `AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key` (optional)
    - `AWS_REGION=us-east-1` (optional, defaults to us-east-1)
    - `AWS_ENDPOINT=https://s3.amazonaws.com` (optional, for S3-compatible services)
  
  > **Note:** You must provide either GCP credentials (`GCP_SA_KEY`) OR AWS credentials (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), but not both. The application will auto-detect the provider based on available credentials.
- `ANTHROPIC_API_KEY=sk-ant-...` (optional)
- `OPENAI_API_KEY=sk-...` (optional)
- `GOOGLE_VERTEX_AI_WEB_CREDENTIALS={"type":"service_account","project_id":"..."}` (JSON string, optional)

**Creation:**
```bash
kubectl create secret generic mcp-gateway-secrets \
  --from-literal=PORT="3002" \
  --from-literal=FRONTEND_URL="https://app.your-domain.com" \
  --from-literal=PINECONE_API_KEY="your_pinecone_api_key" \
  --from-literal=PINECONE_INDEX="your_pinecone_index" \
  --from-literal=REDIS_URL="redis://redis:6379" \
  --from-literal=BUCKET_NAME_FILE_MANAGER="your_storage_bucket" \
  --from-literal=SPENDHQ_BASE_URL="https://your-spendhq-url.com" \
  --from-literal=SPENDHQ_CLIENT_ID="your_spendhq_client_id" \
  --from-literal=SPENDHQ_CLIENT_SECRET="your_spendhq_client_secret" \
  --from-literal=SPENDHQ_TOKEN_URL="https://your-spendhq-token-url.com" \
  --from-literal=SPENDHQ_SS_HOST="your_singlestore_host" \
  --from-literal=SPENDHQ_SS_USERNAME="your_singlestore_username" \
  --from-literal=SPENDHQ_SS_PASSWORD="your_singlestore_password" \
  --from-literal=SPENDHQ_SS_PORT="3306" \
  --from-literal=GOOGLE_PROJECTID="your_google_project_id" \
  # Storage credentials (choose GCS OR AWS, not both):
  # For GCS:
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3:
  # --from-literal=AWS_ACCESS_KEY_ID="your_aws_access_key_id" \
  # --from-literal=AWS_SECRET_ACCESS_KEY="your_aws_secret_access_key" \
  # --from-literal=AWS_REGION="us-east-1" \
  # --from-literal=AWS_ENDPOINT="https://s3.amazonaws.com" \
  --from-literal=ANTHROPIC_API_KEY="sk-ant-..." \
  --from-literal=OPENAI_API_KEY="sk-..." \
  --from-literal=GOOGLE_VERTEX_AI_WEB_CREDENTIALS='{"type":"service_account","project_id":"..."}' \
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
  - Encryption keys yearly
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
