# Script to create/update Kubernetes secrets from .env file
# Usage: .\create-secrets-from-env.ps1

$ErrorActionPreference = "Stop"

# Check if .env file exists
$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found! Copy .env.example to .env and fill in your values."
    exit 1
}

Write-Host "Reading secrets from .env file..." -ForegroundColor Cyan

# Load environment variables from .env file
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $envVars[$key] = $value
        }
    }
}

# Validate required variables
$requiredVars = @(
    "SPRING_DATASOURCE_URL",
    "SPRING_DATASOURCE_USERNAME", 
    "SPRING_DATASOURCE_PASSWORD",
    "JWT_SECRET",
    "MAIL_USERNAME",
    "MAIL_PASSWORD"
)

$missing = @()
foreach ($var in $requiredVars) {
    if (-not $envVars.ContainsKey($var) -or [string]::IsNullOrWhiteSpace($envVars[$var])) {
        $missing += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Missing required environment variables: $($missing -join ', ')"
    exit 1
}

Write-Host "Creating Kubernetes secrets..." -ForegroundColor Cyan

# Create or update gearup-secrets
kubectl create secret generic gearup-secrets `
    --namespace=gearup `
    --from-literal=spring-datasource-url="$($envVars['SPRING_DATASOURCE_URL'])" `
    --from-literal=spring-datasource-username="$($envVars['SPRING_DATASOURCE_USERNAME'])" `
    --from-literal=spring-datasource-password="$($envVars['SPRING_DATASOURCE_PASSWORD'])" `
    --from-literal=jwt-secret="$($envVars['JWT_SECRET'])" `
    --from-literal=mail-username="$($envVars['MAIL_USERNAME'])" `
    --from-literal=mail-password="$($envVars['MAIL_PASSWORD'])" `
    --dry-run=client -o yaml | kubectl apply -f -

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Created/updated secret: gearup-secrets" -ForegroundColor Green
} else {
    Write-Error "Failed to create gearup-secrets"
    exit 1
}

# Create or update redis-secret
$redisPassword = if ($envVars.ContainsKey('REDIS_PASSWORD')) { $envVars['REDIS_PASSWORD'] } else { "" }
kubectl create secret generic redis-secret `
    --namespace=gearup `
    --from-literal=redis-password="$redisPassword" `
    --dry-run=client -o yaml | kubectl apply -f -

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Created/updated secret: redis-secret" -ForegroundColor Green
} else {
    Write-Error "Failed to create redis-secret"
    exit 1
}

Write-Host "`nSecrets created successfully!" -ForegroundColor Green
Write-Host "You can now delete the secrets.yaml file or keep it as a backup template." -ForegroundColor Yellow
