-- ============================================================
-- 008: Storage Buckets
-- Refers to DATABASE_SCHEMA.md section 5.
-- Convention: files are stored under a folder named after the
-- uploading user's uid, e.g. avatars/<uid>/photo.jpg — this lets
-- the policies check ownership via storage.foldername(name)[1].
-- ============================================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('event-photos', 'event-photos', false)
on conflict (id) do nothing;

-- avatars: public read (profile photos are fine to be public),
-- owner-only write, path must start with the uploader's own uid.
create policy "avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_owner_write"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- event-photos: private bucket, readable/writable by any
-- authenticated group member (documentation photos are shared).
create policy "event_photos_bucket_read"
  on storage.objects for select
  using (bucket_id = 'event-photos' and auth.uid() is not null);

create policy "event_photos_bucket_insert"
  on storage.objects for insert
  with check (bucket_id = 'event-photos' and auth.uid() is not null);