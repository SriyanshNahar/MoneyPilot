#!/usr/bin/env bash
# Creates the `avatars` storage bucket + RLS policies (confirmed missing on
# the live project as of 2026-07-21 — see supabase/migrations/20260721000000_create_avatars_bucket.sql).
#
# Needs the Supabase CLI logged in and linked to this project, OR run the
# migration file's SQL directly in the Dashboard's SQL Editor if you don't
# want to install the CLI.
set -euo pipefail

PROJECT_REF="rfrddfjtmrtfhqlvvqzf"

if ! command -v supabase &>/dev/null; then
  echo "Supabase CLI not found. Install it first:"
  echo "  npm install -g supabase"
  echo "  (or) brew install supabase/tap/supabase"
  echo
  echo "Then either re-run this script, or just paste the contents of"
  echo "supabase/migrations/20260721000000_create_avatars_bucket.sql into:"
  echo "  https://supabase.com/dashboard/project/$PROJECT_REF/sql/new"
  exit 1
fi

echo "Linking to project $PROJECT_REF (will prompt for login if needed)..."
supabase link --project-ref "$PROJECT_REF"

echo "Applying migration: create avatars bucket + RLS policies..."
supabase db push

echo
echo "Verifying..."
supabase storage ls --linked || true

echo "Done. Confirm 'avatars' is listed above."
