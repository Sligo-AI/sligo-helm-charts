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
- `PORT=3000`
- `OPENAI_API_KEY=sk-...` (required for RAG embeddings)
- **Authentication (@Sligo-AI/auth)** – Set `AUTH_PROVIDER=workos` (default), `oidc`, or `saml`. Then provide the matching credentials:
  - **When `AUTH_PROVIDER=workos`:** `WORKOS_API_KEY`, `WORKOS_CLIENT_ID`, `WORKOS_COOKIE_PASSWORD=<generate with: openssl rand -base64 32>`
  - **When `AUTH_PROVIDER=oidc`:** `AUTH_SESSION_SECRET=<min 32 chars>`, `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`; optional: `OIDC_SCOPES`, `OIDC_DEFAULT_ORG_ID`, `OIDC_DEFAULT_ORG_NAME`
  - **When `AUTH_PROVIDER=saml`:** `AUTH_SESSION_SECRET=<min 32 chars>`, `SAML_ENTRYPOINT`, `SAML_ISSUER`, `SAML_CERT` (IdP cert PEM); optional: `SAML_DEFAULT_ORG_ID`, `SAML_DEFAULT_ORG_NAME`
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

**Optional Keys:**
- `GOOGLE_PROJECTID=your_google_project_id` (optional, but recommended)
- **Authentication (optional):**
  - `AUTH_PROVIDER=workos` (default), `oidc`, or `saml`. Use `oidc` or `saml` for your own IdP / enterprise SSO.
  - `AUTH_BASE_URL=https://app.your-domain.com` (fallback if `NEXT_PUBLIC_URL` not set)
  - `AUTH_SESSION_SECRET=<min 32 chars>` (required when using OIDC or SAML; used for session signing)
  - `AUTH_COOKIE_NAME=sligo_session` (optional; default session cookie name)
- **Vector store credentials (optional; multiple allowed):**  
  Each knowledge base folder is configured with a vector store (Pinecone, SingleStore, Azure AI Search, or future providers). Provide credentials only for the stores you use. You can set multiple stores in the same secret; they do not overlap. The app uses the credentials that match the folder’s selected store.
  - **Default when a folder has no selection:** `RAG_VECTOR_STORE=pinecone` (or `singlestore` or `azureaisearch`). Omit to default to Pinecone.
  - **Pinecone (optional):** `PINECONE_API_KEY`, `PINECONE_INDEX`. Optional: `PINECONE_ENVIRONMENT` (legacy SDK).
  - **SingleStore (optional):** `SINGLESTORE_HOST`, `SINGLESTORE_PORT`, `SINGLESTORE_USER`, `SINGLESTORE_PASSWORD`, `SINGLESTORE_DATABASE`. Optional: `SINGLESTORE_*` table/field names (see app .env.example).
  - **Azure AI Search (optional):** `AZURE_AISEARCH_ENDPOINT=https://your-service.search.windows.net`, `AZURE_AISEARCH_KEY=your_admin_key`, `AZURE_AISEARCH_INDEX=vectorsearch` (optional, default), `AZURE_AISEARCH_QUERY_TYPE=similarity_hybrid` (optional: `similarity`, `similarity_hybrid`, `semantic_hybrid`).
  - Future vector stores will have their own optional env vars; add them alongside these when available.
- **Storage:**
  - `STORAGE_PROVIDER=gcs` or `STORAGE_PROVIDER=s3` (optional; default is `gcs` when unset). When set, this chooses the storage provider; otherwise the app infers from credentials.
  - **GCS (Google Cloud Storage):**
    - `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
    - `RAG_SA_KEY={"type":"service_account","project_id":"..."}` (JSON string, optional)
  - **AWS S3:**
    - `AWS_ACCESS_KEY_ID=your_aws_access_key_id` (optional)
    - `AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key` (optional)
    - `AWS_REGION=us-east-1` (optional, defaults to us-east-1)
    - `AWS_ENDPOINT=https://s3.amazonaws.com` (optional, for S3-compatible services)
  
  > **Note:** Provide credentials for the provider you use. Set `STORAGE_PROVIDER` to `gcs` or `s3` to choose explicitly; when unset, the app defaults to `gcs` and can infer from which credentials are present.

**Creation:**
```bash
kubectl create secret generic nextjs-secrets \
  --from-literal=BACKEND_URL="https://your-backend-url.com" \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -base64 32)" \
  --from-literal=MCP_GATEWAY_URL="http://mcp-gateway:3002" \
  --from-literal=NEXT_PUBLIC_URL="https://app.your-domain.com" \
  --from-literal=NODE_ENV="production" \
  --from-literal=PORT="3000" \
  --from-literal=AUTH_PROVIDER="workos" \
  --from-literal=WORKOS_API_KEY="your_workos_api_key" \
  --from-literal=WORKOS_CLIENT_ID="your_workos_client_id" \
  --from-literal=WORKOS_COOKIE_PASSWORD="$(openssl rand -base64 32)" \
  # For OIDC instead of WorkOS: set AUTH_PROVIDER=oidc, AUTH_SESSION_SECRET, OIDC_ISSUER, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET (and optional OIDC_SCOPES, OIDC_DEFAULT_ORG_*)
  # For SAML: set AUTH_PROVIDER=saml, AUTH_SESSION_SECRET, SAML_ENTRYPOINT, SAML_ISSUER, SAML_CERT (and optional SAML_DEFAULT_ORG_*)
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
  # Vector store credentials (optional; include only the stores you use; multiple allowed):
  # --from-literal=RAG_VECTOR_STORE="pinecone" \
  # --from-literal=PINECONE_API_KEY="your_pinecone_api_key" \
  # --from-literal=PINECONE_INDEX="your_pinecone_index" \
  # --from-literal=SINGLESTORE_HOST="your_singlestore_host" \
  # --from-literal=SINGLESTORE_PORT="3306" \
  # --from-literal=SINGLESTORE_USER="your_singlestore_user" \
  # --from-literal=SINGLESTORE_PASSWORD="your_singlestore_password" \
  # --from-literal=SINGLESTORE_DATABASE="your_database" \
  # Azure AI Search (optional): --from-literal=RAG_VECTOR_STORE="azureaisearch" \
  # --from-literal=AZURE_AISEARCH_ENDPOINT="https://your-service.search.windows.net" \
  # --from-literal=AZURE_AISEARCH_KEY="your_admin_key" \
  # --from-literal=AZURE_AISEARCH_INDEX="vectorsearch" \
  # --from-literal=AZURE_AISEARCH_QUERY_TYPE="similarity_hybrid" \
  # Storage (optional): set provider explicitly; default is gcs
  # --from-literal=STORAGE_PROVIDER="gcs" \
  # For GCS:
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  --from-literal=RAG_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3:
  # --from-literal=STORAGE_PROVIDER="s3" \
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
- **Storage:**
  - `STORAGE_PROVIDER=gcs` or `STORAGE_PROVIDER=s3` (optional; default is `gcs` when unset).
  - **GCS:** `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (optional)
  - **AWS S3:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION=us-east-1` (optional), `AWS_ENDPOINT` (optional)
  
  > **Note:** Set `STORAGE_PROVIDER` to choose the provider; when unset, the app defaults to `gcs` and infers from credentials.
- `ANTHROPIC_API_KEY=sk-ant-...` (optional)
- `GOOGLE_VERTEX_AI_WEB_CREDENTIALS={"type":"service_account","project_id":"..."}` (JSON string, optional)
- `OPENAI_BASE_URL=https://api.openai.com/v1` (defaults to `https://api.openai.com/v1` if not set)
- **Azure OpenAI (optional):** `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_API_INSTANCE_NAME`, `AZURE_OPENAI_API_VERSION`, `AZURE_OPENAI_BASE_PATH` (e.g. `https://your-resource.openai.azure.com/openai/deployments/your-deployment`)
- `LANGSMITH_API_KEY=your_langsmith_api_key` (optional)
- `LANGCHAIN_CALLBACKS_BACKGROUND=false` (optional, default `false`)

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
  # Storage (optional): STORAGE_PROVIDER=gcs or s3; then GCS or AWS credentials
  # --from-literal=STORAGE_PROVIDER="gcs" \
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3: --from-literal=STORAGE_PROVIDER="s3" \ and AWS_* keys
  --from-literal=ANTHROPIC_API_KEY="sk-ant-..." \
  --from-literal=GOOGLE_VERTEX_AI_WEB_CREDENTIALS='{"type":"service_account","project_id":"..."}' \
  --from-literal=OPENAI_BASE_URL="https://api.openai.com/v1" \
  --from-literal=LANGSMITH_API_KEY="your_langsmith_api_key" \
  # Azure OpenAI (optional):
  # --from-literal=AZURE_OPENAI_API_KEY="your_azure_openai_key" \
  # --from-literal=AZURE_OPENAI_API_INSTANCE_NAME="your_instance_name" \
  # --from-literal=AZURE_OPENAI_API_VERSION="2024-02-15-preview" \
  # --from-literal=AZURE_OPENAI_BASE_PATH="https://your-resource.openai.azure.com/openai/deployments/your-deployment" \
  # --from-literal=LANGCHAIN_CALLBACKS_BACKGROUND="false" \
  -n sligo
```

### 3. mcp-gateway-secrets

MCP Gateway secrets.

**Required Keys:**
- `PORT=3002`
- `FRONTEND_URL=https://app.your-domain.com`
- `OPENAI_API_KEY=sk-...` (required for RAG embeddings; also used for LLMs if set)
- `REDIS_URL=redis://redis:6379` (or external Redis URL)
- `BUCKET_NAME_FILE_MANAGER=your_storage_bucket`

**Optional Keys:**
- `GOOGLE_PROJECTID=your_google_project_id` (optional)
- **SpendHQ server (optional; required when using SpendHQ tools):** `SPENDHQ_BASE_URL`, `SPENDHQ_CLIENT_ID`, `SPENDHQ_CLIENT_SECRET`, `SPENDHQ_TOKEN_URL`, `SPENDHQ_SS_HOST`, `SPENDHQ_SS_USERNAME`, `SPENDHQ_SS_PASSWORD`, `SPENDHQ_SS_PORT=3306`
- **Perplexity server (optional; required when using Perplexity tools):** `PERPLEXITY_API_KEY`
- **Tavily server (optional; required when using Tavily tools):** `TAVILY_API_KEY`
- **Sirion server (optional):** `SIRION_BASE_URL`, `SIRION_CLIENT_ID`, `SIRION_CLIENT_SECRET`
- **Storage:**
  - `STORAGE_PROVIDER=gcs` or `STORAGE_PROVIDER=s3` (optional; default is `gcs` when unset).
  - **GCS:** `GCP_SA_KEY={"type":"service_account","project_id":"..."}` (optional)
  - **AWS S3:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_ENDPOINT` (optional)
  
  > **Note:** Set `STORAGE_PROVIDER` to choose the provider; when unset, the app defaults to `gcs` and infers from credentials.
- `ANTHROPIC_API_KEY=sk-ant-...` (optional)
- `GOOGLE_VERTEX_AI_WEB_CREDENTIALS={"type":"service_account","project_id":"..."}` (JSON string, optional)
- **Vector store credentials (optional; multiple allowed):**  
  Managed knowledge base folders each use a chosen vector store (Pinecone, SingleStore, Azure AI Search, or future providers). Provide credentials only for the stores you use. You can set multiple stores in the same secret; they do not overlap.
  - **Default when a folder has no selection:** `RAG_VECTOR_STORE=pinecone` (or `singlestore` or `azureaisearch`). Omit to default to Pinecone.
  - **Pinecone (optional):** `PINECONE_API_KEY`, `PINECONE_INDEX`. Optional: `PINECONE_ENVIRONMENT`.
  - **SingleStore (optional):** `SINGLESTORE_HOST`, `SINGLESTORE_PORT`, `SINGLESTORE_USER`, `SINGLESTORE_PASSWORD`, `SINGLESTORE_DATABASE`. Optional table/field env vars (see mcp-gateway .env.example).
  - **Azure AI Search (optional):** `AZURE_AISEARCH_ENDPOINT`, `AZURE_AISEARCH_KEY`, `AZURE_AISEARCH_INDEX`, `AZURE_AISEARCH_QUERY_TYPE` (see nextjs-secrets for details).
  - Future vector stores will have their own optional env vars; add them alongside these when available.

**Creation:**
```bash
kubectl create secret generic mcp-gateway-secrets \
  --from-literal=PORT="3002" \
  --from-literal=FRONTEND_URL="https://app.your-domain.com" \
  --from-literal=OPENAI_API_KEY="sk-..." \
  --from-literal=REDIS_URL="redis://redis:6379" \
  --from-literal=BUCKET_NAME_FILE_MANAGER="your_storage_bucket" \
  --from-literal=GOOGLE_PROJECTID="your_google_project_id" \
  # SpendHQ (optional; include when using SpendHQ server):
  # --from-literal=SPENDHQ_BASE_URL="https://your-spendhq-url.com" \
  # --from-literal=SPENDHQ_CLIENT_ID="your_spendhq_client_id" \
  # --from-literal=SPENDHQ_CLIENT_SECRET="your_spendhq_client_secret" \
  # --from-literal=SPENDHQ_TOKEN_URL="https://your-spendhq-token-url.com" \
  # --from-literal=SPENDHQ_SS_HOST="your_singlestore_host" \
  # --from-literal=SPENDHQ_SS_USERNAME="your_singlestore_username" \
  # --from-literal=SPENDHQ_SS_PASSWORD="your_singlestore_password" \
  # --from-literal=SPENDHQ_SS_PORT="3306" \
  # Perplexity (optional): --from-literal=PERPLEXITY_API_KEY="your_perplexity_api_key" \
  # Tavily (optional): --from-literal=TAVILY_API_KEY="your_tavily_api_key" \
  # Sirion (optional): --from-literal=SIRION_BASE_URL="..." \ --from-literal=SIRION_CLIENT_ID="..." \ --from-literal=SIRION_CLIENT_SECRET="..." \
  # Vector store credentials (optional; include only the stores you use; multiple allowed):
  # --from-literal=RAG_VECTOR_STORE="pinecone" \
  # --from-literal=PINECONE_API_KEY="your_pinecone_api_key" \
  # --from-literal=PINECONE_INDEX="your_pinecone_index" \
  # --from-literal=SINGLESTORE_HOST="your_singlestore_host" \
  # --from-literal=SINGLESTORE_PORT="3306" \
  # --from-literal=SINGLESTORE_USER="your_singlestore_user" \
  # --from-literal=SINGLESTORE_PASSWORD="your_singlestore_password" \
  # --from-literal=SINGLESTORE_DATABASE="your_database" \
  # Azure AI Search: --from-literal=RAG_VECTOR_STORE="azureaisearch" \
  # --from-literal=AZURE_AISEARCH_ENDPOINT="https://your-service.search.windows.net" \
  # --from-literal=AZURE_AISEARCH_KEY="your_admin_key" \
  # --from-literal=AZURE_AISEARCH_INDEX="vectorsearch" \
  # --from-literal=AZURE_AISEARCH_QUERY_TYPE="similarity_hybrid" \
  # Storage (optional): STORAGE_PROVIDER=gcs or s3; then GCS or AWS credentials
  # --from-literal=STORAGE_PROVIDER="gcs" \
  --from-literal=GCP_SA_KEY='{"type":"service_account","project_id":"..."}' \
  # OR for AWS S3: --from-literal=STORAGE_PROVIDER="s3" \ and AWS_* keys
  --from-literal=ANTHROPIC_API_KEY="sk-ant-..." \
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
