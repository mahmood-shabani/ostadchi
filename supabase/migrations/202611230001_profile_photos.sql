-- Ostadchi profile photo storage.
-- Run once in Supabase SQL Editor before testing profile photo uploads.
alter table public.profiles add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photos', 'profile-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "profile photos are publicly readable" on storage.objects;
create policy "profile photos are publicly readable" on storage.objects
for select to anon, authenticated using (bucket_id = 'profile-photos');

drop policy if exists "users upload their own profile photo" on storage.objects;
create policy "users upload their own profile photo" on storage.objects
for insert to authenticated with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "users update their own profile photo" on storage.objects;
create policy "users update their own profile photo" on storage.objects
for update to authenticated using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "users delete their own profile photo" on storage.objects;
create policy "users delete their own profile photo" on storage.objects
for delete to authenticated using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
