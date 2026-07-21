# Windows equivalent of setup_storage.sh — creates the `avatars` storage
# bucket + RLS policies (confirmed missing on the live project as of
# 2026-07-21: GET /storage/v1/bucket returned []).

$ErrorActionPreference = "Stop"
$ProjectRef = "rfrddfjtmrtfhqlvvqzf"

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "Supabase CLI not found. Install with: npm install -g supabase"
    Write-Host ""
    Write-Host "Alternatively, skip the CLI entirely: open"
    Write-Host "  https://supabase.com/dashboard/project/$ProjectRef/sql/new"
    Write-Host "and paste the contents of"
    Write-Host "  supabase/migrations/20260721000000_create_avatars_bucket.sql"
    exit 1
}

Write-Host "Linking to project $ProjectRef (will prompt for login if needed)..."
supabase link --project-ref $ProjectRef

Write-Host "Applying migration: create avatars bucket + RLS policies..."
supabase db push

Write-Host ""
Write-Host "Verifying..."
supabase storage ls --linked

Write-Host "Done. Confirm 'avatars' is listed above."
