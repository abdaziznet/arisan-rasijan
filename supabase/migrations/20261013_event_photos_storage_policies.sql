-- ============================================================
-- 20261013: Event Photos Storage - Add DELETE policy and make public
-- Fixes: family members can delete photos they uploaded or admin can delete any
-- ============================================================

-- Update bucket to be public (gallery is shared among family members)
update storage.buckets
set public = true
where id = 'event-photos';

-- DELETE policy: uploader (owner) or admin can delete
-- File path format: periodId/timestamp.ext, so we need to check uploaded_by from event_photos table
-- We use a policy that checks if the user is the uploader or is an admin
create policy "event_photos_bucket_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'event-photos'
  and exists (
    select 1 from public.event_photos ep
    where ep.photo_url like '%' || storage.objects.name || '%'
    and (ep.uploaded_by = auth.uid() or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    ))
  )
);