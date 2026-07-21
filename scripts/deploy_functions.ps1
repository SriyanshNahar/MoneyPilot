# Windows equivalent of deploy_functions.sh — deploys the 4 edge functions
# confirmed NOT deployed on the live project as of 2026-07-21.
#
# Requires: Supabase CLI (npm install -g supabase), logged in to the
# account that owns this project.

$ErrorActionPreference = "Stop"
$ProjectRef = "rfrddfjtmrtfhqlvvqzf"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "Supabase CLI not found. Install with: npm install -g supabase"
    exit 1
}

Write-Host "Linking to project $ProjectRef (will prompt for login if needed)..."
supabase link --project-ref $ProjectRef

$functions = @("ai-chat", "razorpay-create-order", "razorpay-verify-payment", "send-alert")
foreach ($fn in $functions) {
    Write-Host ""
    Write-Host "=== Deploying $fn ==="
    supabase functions deploy $fn --no-verify-jwt
}

Write-Host ""
Write-Host "Verifying..."
foreach ($fn in $functions) {
    $url = "https://$ProjectRef.supabase.co/functions/v1/$fn"
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Options -UseBasicParsing
        Write-Host "  OK $fn -> $($resp.StatusCode)"
    } catch {
        Write-Host "  FAIL $fn -> $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Next: copy scripts/secrets_template.env to scripts/secrets.env, fill in real values, then:"
Write-Host "  supabase secrets set --env-file scripts/secrets.env"
