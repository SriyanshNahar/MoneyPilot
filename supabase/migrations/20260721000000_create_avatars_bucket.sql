-- Creates the `avatars` storage bucket used by Settings → profile photo
-- upload (see lib/data/repositories/profile_repository.dart) and the
-- profile-sheet avatar in the React app it mirrors.
--
-- Verified live on 2026-07-21 that this bucket does NOT yet exist on the
-- project (rfrddfjtmrtfhqlvvqzf) — `GET /storage/v1/bucket` returned `[]`.
-- Avatar upload will fail with "Bucket not found" until this runs.
--
-- Private bucket: the app never reads avatars via public URL, it always
-- calls storage.createSignedUrl(), so objects stay private and each user's
-- avatar is scoped to a folder named after their own auth.uid().
--
-- Run with:
--   supabase db push
-- or paste this file's contents into the Supabase Dashboard's SQL Editor.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do nothing;

-- Each user may read/write/delete only objects under their own `${uid}/...`
-- folder — matches the path convention used by ProfileRepository.uploadAvatar.
create policy "avatars: owners can read own folder"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: owners can upload to own folder"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: owners can update own folder"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: owners can delete own folder"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
