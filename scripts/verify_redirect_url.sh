#!/usr/bin/env bash
# Verifies (and optionally adds) the OAuth redirect URL the Flutter app
# needs — io.moneypilot.app://login-callback — in Supabase Auth's allow-list.
#
# I could not check this myself during the audit: the anon key only exposes
# GET /auth/v1/settings (which confirms *providers* are enabled — I verified
# google:true and apple:true live — but not the redirect URL allow-list,
# which lives in project config and requires a Management API token).
#
# Get a personal access token at https://supabase.com/dashboard/account/tokens
# then run:
#   SUPABASE_ACCESS_TOKEN=sbp_xxx ./scripts/verify_redirect_url.sh
set -euo pipefail

PROJECT_REF="rfrddfjtmrtfhqlvvqzf"
REDIRECT_URL="io.moneypilot.app://login-callback"

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
  echo "SUPABASE_ACCESS_TOKEN not set."
  echo
  echo "Manual check instead (always works, no token needed):"
  echo "  1. https://supabase.com/dashboard/project/$PROJECT_REF/auth/url-configuration"
  echo "  2. Confirm '$REDIRECT_URL' is listed under 'Redirect URLs'."
  echo "  3. If not, add it and Save."
  exit 1
fi

echo "Fetching current auth config..."
CONFIG=$(curl -s "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN")

if echo "$CONFIG" | grep -q "$REDIRECT_URL"; then
  echo "✓ $REDIRECT_URL is already in the redirect allow-list."
  exit 0
fi

echo "✗ $REDIRECT_URL is NOT in the redirect allow-list. Current list:"
echo "$CONFIG" | grep -o '"uri_allow_list":"[^"]*"' || echo "$CONFIG"

CURRENT_LIST=$(echo "$CONFIG" | grep -o '"uri_allow_list":"[^"]*"' | sed -E 's/"uri_allow_list":"(.*)"/\1/')
NEW_LIST="${CURRENT_LIST:+$CURRENT_LIST,}$REDIRECT_URL"

read -p "Add it now via the Management API? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl -s -X PATCH "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"uri_allow_list\": \"$NEW_LIST\"}" \
    -w "\nstatus:%{http_code}\n"
else
  echo "Skipped. Add it manually at:"
  echo "  https://supabase.com/dashboard/project/$PROJECT_REF/auth/url-configuration"
fi
