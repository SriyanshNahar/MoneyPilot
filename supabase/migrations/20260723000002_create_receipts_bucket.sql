-- Backend Phase 1: `receipts` storage bucket. The `expenses` table already
-- has a `receipt_url` column in the original schema (unused by the current
-- Flutter UI, which is frozen for this phase) — this bucket is the backend
-- half of that pre-existing column, mirroring the `avatars` bucket's setup
-- exactly (see 20260721000000_create_avatars_bucket.sql).
--
-- Private bucket: receipts are personal financial documents. Each user's
-- files live under a folder named after their own auth.uid(); access is
-- always via storage.createSignedUrl(), never a public URL.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

drop policy if exists "receipts: owners can read own folder" on storage.objects;
create policy "receipts: owners can read own folder"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "receipts: owners can upload to own folder" on storage.objects;
create policy "receipts: owners can upload to own folder"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "receipts: owners can update own folder" on storage.objects;
create policy "receipts: owners can update own folder"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "receipts: owners can delete own folder" on storage.objects;
create policy "receipts: owners can delete own folder"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);
