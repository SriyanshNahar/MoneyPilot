#!/usr/bin/env bash
# Deploys the 4 edge functions this app depends on and are confirmed NOT
# deployed on the live project as of 2026-07-21 (all 4 returned 404 when
# hit directly). AI Coach and Razorpay payments do not work until this runs.
#
# Requires: Supabase CLI installed and logged into the account that owns
# this project (`supabase login`). Secrets must be set separately (see
# secrets_template.env in this folder) before these functions will work
# even once deployed.
set -euo pipefail

PROJECT_REF="rfrddfjtmrtfhqlvvqzf"
cd "$(dirname "$0")/.."

if ! command -v supabase &>/dev/null; then
  echo "Supabase CLI not found. Install with: npm install -g supabase"
  exit 1
fi

echo "Linking to project $PROJECT_REF (will prompt for login if needed)..."
supabase link --project-ref "$PROJECT_REF"

for fn in ai-chat razorpay-create-order razorpay-verify-payment send-alert; do
  echo
  echo "=== Deploying $fn ==="
  supabase functions deploy "$fn" --no-verify-jwt
done

echo
echo "All 4 functions deployed. Verifying..."
for fn in ai-chat razorpay-create-order razorpay-verify-payment send-alert; do
  status=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS \
    "https://$PROJECT_REF.supabase.co/functions/v1/$fn")
  if [ "$status" = "200" ] || [ "$status" = "204" ]; then
    echo "  ✓ $fn is live"
  else
    echo "  ✗ $fn returned HTTP $status — check 'supabase functions logs $fn'"
  fi
done

echo
echo "Next: set secrets — see scripts/secrets_template.env — with:"
echo "  supabase secrets set --env-file scripts/secrets.env"
