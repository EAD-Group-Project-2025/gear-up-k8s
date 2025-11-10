# Kubernetes Configuration Management Guide

## Understanding Secrets vs ConfigMaps

### 🔐 Secrets (.env file) - SENSITIVE DATA ONLY
**What belongs here:**
- ✅ Database passwords
- ✅ JWT secrets
- ✅ Email passwords
- ✅ API keys/tokens
- ✅ Any credentials

**Managed via:**
- `.env` file (NOT committed to git)
- `create-secrets-from-env.ps1` script

### ⚙️ ConfigMaps (configmap.yaml) - NON-SENSITIVE DATA
**What belongs here:**
- ✅ CORS allowed origins
- ✅ Service URLs (public endpoints)
- ✅ Timeouts and limits
- ✅ Feature flags
- ✅ Application settings
- ✅ Port numbers

**Managed via:**
- `configmap.yaml` (hardcoded values, can be committed to git)

---

## Working with Secrets

### Setup Steps:

1. **Copy the example file:**
   ```powershell
   Copy-Item .env.example .env
   ```

2. **Edit `.env` with your SENSITIVE values only:**
   ```powershell
   notepad .env
   ```

3. **Create Kubernetes secrets:**
   ```powershell
   .\create-secrets-from-env.ps1
   ```

### Updating Secrets:
```powershell
# 1. Edit .env file (sensitive data only)
notepad .env

# 2. Re-run the script (it will update existing secrets)
.\create-secrets-from-env.ps1

# 3. Restart deployments to pick up new values
kubectl rollout restart deployment/backend -n gearup
```

---

## Working with ConfigMaps

### Editing ConfigMaps:

1. **Edit configmap.yaml directly:**
   ```powershell
   notepad configmap.yaml
   ```

2. **Apply the changes:**
   ```powershell
   kubectl apply -f configmap.yaml
   ```

3. **Restart deployments to pick up new values:**
   ```powershell
   kubectl rollout restart deployment/backend -n gearup
   ```

### Example ConfigMap values:
```yaml
data:
  # CORS (non-sensitive, public information)
  CORS_ALLOWED_ORIGINS: "http://localhost:3000,http://34.42.2.114"
  
  # Service URLs (non-sensitive, public endpoints)
  CHATBOT_PYTHON_SERVICE_URL: "https://your-chatbot.azurecontainerapps.io"
  
  # Timeouts and limits
  CHATBOT_PYTHON_SERVICE_TIMEOUT: "30"
  JWT_EXPIRATION: "43200000"
```

---

## Quick Reference

| Data Type | Storage | File | Committed to Git? | Update Command |
|-----------|---------|------|-------------------|----------------|
| **Passwords** | Secret | `.env` | ❌ NO | `.\create-secrets-from-env.ps1` |
| **API Keys** | Secret | `.env` | ❌ NO | `.\create-secrets-from-env.ps1` |
| **CORS Origins** | ConfigMap | `configmap.yaml` | ✅ YES | `kubectl apply -f configmap.yaml` |
| **Service URLs** | ConfigMap | `configmap.yaml` | ✅ YES | `kubectl apply -f configmap.yaml` |
| **Timeouts** | ConfigMap | `configmap.yaml` | ✅ YES | `kubectl apply -f configmap.yaml` |

---

## Security Best Practices:

- ✅ Never commit `.env` file to git (already in `.gitignore`)
- ✅ Keep `.env.example` updated when adding new secrets
- ✅ Use strong passwords and rotate them regularly
- ✅ For Gmail, use App Passwords, not your account password
- ✅ ConfigMaps can be committed to git (they're not sensitive)
- ✅ Keep production secrets separate from development
