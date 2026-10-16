-- Issue 7: donation payment methods, verification, unique payment codes,
-- and admin-managed payment settings/QRIS image.

-- Existing rows are historical received donations. New reports default to
-- pending payment and require explicit administrator verification.
alter table public.donations
  add column payment_method text,
  add column status text,
  add column received_amount numeric,
  add column unique_code smallint,
  add column expires_at timestamptz,
  add column payment_reference text,
  add column payment_proof_path text,
  add column verified_by uuid references public.profiles(id),
  add column verified_at timestamptz,
  add column verification_note text;

update public.donations set status = 'verified' where status is null;

alter table public.donations
  alter column status set default 'pending_payment',
  alter column status set not null,
  add constraint donations_payment_method_check
    check (payment_method is null or payment_method in ('cash', 'transfer', 'qris')),
  add constraint donations_payment_method_required_check
    check (payment_method is not null or status = 'verified'),
  add constraint donations_status_check
    check (status in ('pending_payment', 'pending_verification', 'needs_review', 'verified', 'rejected', 'expired')),
  add constraint donations_positive_amount_check check (amount > 0) not valid,
  add constraint donations_unique_code_check
    check (
      (payment_method is null and unique_code is null)
      or (payment_method in ('transfer', 'qris') and unique_code is not null and unique_code between 1 and 150)
      or (payment_method = 'cash' and unique_code is null)
    );

-- `amount` is the reported donation amount; payment_amount adds the unique
-- reconciliation code for transfer and QRIS.
alter table public.donations
  add column payment_amount numeric generated always as (
    case
      when payment_method in ('transfer', 'qris') and unique_code is not null
        then amount + unique_code
      else amount
    end
  ) stored;

create index donations_member_created_at_idx on public.donations (member_id, created_at desc);
create index donations_verification_queue_idx on public.donations (status, created_at desc)
  where status in ('pending_payment', 'pending_verification', 'needs_review');
create unique index donations_active_unique_code_idx on public.donations (unique_code)
  where payment_method in ('transfer', 'qris')
    and status in ('pending_payment', 'pending_verification', 'needs_review');

-- One serialized code pool shared by transfer and QRIS. The trigger ignores
-- client-supplied codes so simultaneous requests cannot reserve the same code.
create or replace function public.assign_donation_unique_code()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  allocated_code smallint;
begin
  if new.payment_method is null or new.payment_method not in ('transfer', 'qris') then
    new.unique_code := null;
    return new;
  end if;

  perform pg_advisory_xact_lock(728401, 7);

  -- Expired requests release codes and become explicit in member history.
  update public.donations
  set status = 'expired'
  where status = 'pending_payment'
    and expires_at is not null
    and expires_at <= now();

  select candidate::smallint into allocated_code
  from generate_series(1, 150) as codes(candidate)
  where not exists (
    select 1 from public.donations d
    where d.unique_code = candidate
      and d.payment_method in ('transfer', 'qris')
      and d.status in ('pending_payment', 'pending_verification', 'needs_review')
  )
  order by candidate
  limit 1;

  if allocated_code is null then
    raise exception 'Semua kode pembayaran unik sedang digunakan.' using errcode = 'P0001';
  end if;

  new.unique_code := allocated_code;
  new.expires_at := now() + interval '24 hours';
  return new;
end;
$$;
revoke all on function public.assign_donation_unique_code() from public, anon, authenticated;

create trigger donations_assign_unique_code_before_insert
before insert on public.donations
for each row execute function public.assign_donation_unique_code();

-- Expire unpaid transfer/QRIS reservations after 24 hours. The allocator also
-- sweeps expired rows before reserving a code as a fallback.
do $$
declare
  existing_job record;
begin
  if to_regclass('cron.job') is not null then
    for existing_job in
      select jobid from cron.job where jobname = 'expire-pending-donation-codes'
    loop
      perform cron.unschedule(existing_job.jobid);
    end loop;
    perform cron.schedule(
      'expire-pending-donation-codes',
      '*/15 * * * *',
      $job$
        update public.donations
        set status = 'expired'
        where status = 'pending_payment'
          and expires_at is not null
          and expires_at <= now();
      $job$
    );
  end if;
end;
$$;

-- Admin-managed payment destination and QRIS image path.
create table public.donation_payment_settings (
  singleton boolean primary key default true check (singleton),
  bank_name text,
  bank_account_name text,
  bank_account_number text,
  qris_image_path text check (qris_image_path is null or qris_image_path like 'qris/%'),
  payment_instructions text,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

insert into public.donation_payment_settings (singleton) values (true)
on conflict (singleton) do nothing;

create or replace function public.stamp_donation_payment_settings()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_by := auth.uid();
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function public.stamp_donation_payment_settings() from public, anon, authenticated;
create trigger donation_payment_settings_stamp_before
before insert or update on public.donation_payment_settings
for each row execute function public.stamp_donation_payment_settings();

alter table public.donation_payment_settings enable row level security;
create policy donation_payment_settings_member_read
  on public.donation_payment_settings for select to authenticated
  using ((select auth.uid()) is not null);
create policy donation_payment_settings_admin_insert
  on public.donation_payment_settings for insert to authenticated
  with check (public.is_admin());
create policy donation_payment_settings_admin_update
  on public.donation_payment_settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
revoke all on public.donation_payment_settings from anon, authenticated;
grant select, insert, update on public.donation_payment_settings to authenticated;

-- Replace broad donation reads with owner/admin reads. Members submit only
-- their own unverified reports; verification updates remain admin-only.
drop policy if exists "donations_select_all" on public.donations;
drop policy if exists "donations_admin_insert" on public.donations;
drop policy if exists "donations_admin_update" on public.donations;

create policy donations_owner_or_admin_read
  on public.donations for select to authenticated
  using (member_id = (select auth.uid()) or public.is_admin());
create policy donations_owner_submit_or_admin_insert
  on public.donations for insert to authenticated
  with check (
    public.is_admin()
    or (
      member_id = (select auth.uid())
      and payment_method in ('cash', 'transfer', 'qris')
      and status in ('pending_payment', 'pending_verification')
      and received_amount is null
      and verified_by is null
      and verified_at is null
      and verification_note is null
    )
  );
create policy donations_admin_update
  on public.donations for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy donations_owner_attach_proof
  on public.donations for update to authenticated
  using (member_id = (select auth.uid()) and status in ('pending_payment', 'pending_verification', 'needs_review'))
  with check (member_id = (select auth.uid()) and status in ('pending_payment', 'pending_verification'));

create or replace function public.stamp_donation_verification()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.status not in ('pending_payment', 'expired') then
    new.expires_at := null;
  end if;

  if new.status = 'verified' and old.status is distinct from 'verified' then
    if new.received_amount is null or new.received_amount <= 0 then
      raise exception 'Nominal diterima wajib diisi untuk mengesahkan donasi.'
        using errcode = '23514';
    end if;
    new.verified_by := coalesce(new.verified_by, auth.uid());
    new.verified_at := coalesce(new.verified_at, now());
    if new.verified_by is null then
      raise exception 'Identitas admin verifikator wajib tersedia.' using errcode = '23514';
    end if;
  end if;

  if new.status in ('needs_review', 'rejected')
    and old.status is distinct from new.status
    and nullif(btrim(new.verification_note), '') is null then
    raise exception 'Catatan wajib diisi untuk status perlu diperiksa atau ditolak.'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger donations_stamp_verification_before
before update of status, received_amount, verified_by, verified_at, verification_note, expires_at
on public.donations
for each row execute function public.stamp_donation_verification();
revoke all on public.donations from anon;
grant select, insert, update on public.donations to authenticated;

-- Members may attach proof/reference or report that payment was sent, but may
-- not edit the amount, owner, payment method, or any verification fields.
create or replace function public.guard_member_donation_update()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if old.status = 'pending_payment'
      and new.status = 'expired'
      and old.expires_at is not null
      and old.expires_at <= now() then
      return new;
    end if;

    if old.member_id is distinct from (select auth.uid())
      or new.id is distinct from old.id
      or new.period_id is distinct from old.period_id
      or new.member_id is distinct from old.member_id
      or new.amount is distinct from old.amount
      or new.payment_method is distinct from old.payment_method
      or new.unique_code is distinct from old.unique_code
      or new.payment_amount is distinct from old.payment_amount
      or new.expires_at is distinct from old.expires_at
      or new.received_amount is distinct from old.received_amount
      or new.verified_by is distinct from old.verified_by
      or new.verified_at is distinct from old.verified_at
      or new.verification_note is distinct from old.verification_note
      or new.created_at is distinct from old.created_at then
      raise exception 'Member hanya dapat menambahkan referensi/bukti dan mengirim status pembayaran.'
        using errcode = '42501';
    end if;

    if new.status not in ('pending_payment', 'pending_verification') then
      raise exception 'Member tidak dapat mengubah status verifikasi donasi.'
        using errcode = '42501';
    end if;

    if new.payment_proof_path is not null
      and new.payment_proof_path not like
        ((select auth.uid())::text || '/' || new.id::text || '/%') then
      raise exception 'Bukti pembayaran harus berada pada folder donasi milik member.'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger donations_guard_member_update_before
before update on public.donations
for each row execute function public.guard_member_donation_update();
revoke all on function public.guard_member_donation_update() from public, anon, authenticated;
revoke all on function public.stamp_donation_verification() from public, anon, authenticated;

-- Append-only verification history, readable only by the owner and admins.
create table public.donation_verification_events (
  id bigint generated always as identity primary key,
  donation_id uuid not null references public.donations(id) on delete cascade,
  changed_by uuid references public.profiles(id),
  old_status text,
  new_status text not null,
  received_amount numeric,
  note text,
  created_at timestamptz not null default now()
);
create index donation_verification_events_donation_idx
  on public.donation_verification_events (donation_id, created_at desc);
alter table public.donation_verification_events enable row level security;
create policy donation_verification_events_owner_or_admin_read
  on public.donation_verification_events for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.donations d
      where d.id = donation_id and d.member_id = (select auth.uid())
    )
  );
revoke all on public.donation_verification_events from anon, authenticated;
grant select on public.donation_verification_events to authenticated;

create or replace function public.record_donation_verification_event()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.donation_verification_events
      (donation_id, changed_by, old_status, new_status, received_amount, note)
    values (new.id, auth.uid(), null, new.status, new.received_amount, new.verification_note);
  elsif old.status is distinct from new.status
    or old.received_amount is distinct from new.received_amount
    or old.verification_note is distinct from new.verification_note then
    insert into public.donation_verification_events
      (donation_id, changed_by, old_status, new_status, received_amount, note)
    values (new.id, auth.uid(), old.status, new.status, new.received_amount, new.verification_note);
  end if;
  return new;
end;
$$;
revoke all on function public.record_donation_verification_event() from public, anon, authenticated;
create trigger donations_record_verification_insert
after insert on public.donations
for each row execute function public.record_donation_verification_event();
create trigger donations_record_verification_update
after update of status, received_amount, verification_note on public.donations
for each row execute function public.record_donation_verification_event();

-- QRIS is publicly readable payment material; only admins can upload, replace,
-- or remove it. Limit the bucket to small image files and a qris/ path.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('donation-settings', 'donation-settings', true, 2097152,
        array['image/png', 'image/jpeg', 'image/webp']::text[])
on conflict (id) do update
set name = excluded.name, public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists donation_settings_admin_upload on storage.objects;
create policy donation_settings_admin_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'donation-settings' and name like 'qris/%' and public.is_admin());
drop policy if exists donation_settings_admin_update on storage.objects;
create policy donation_settings_admin_update on storage.objects for update to authenticated
  using (bucket_id = 'donation-settings' and name like 'qris/%' and public.is_admin())
  with check (bucket_id = 'donation-settings' and name like 'qris/%' and public.is_admin());
drop policy if exists donation_settings_admin_delete on storage.objects;
create policy donation_settings_admin_delete on storage.objects for delete to authenticated
  using (bucket_id = 'donation-settings' and name like 'qris/%' and public.is_admin());

-- Private evidence images/PDFs use <member uid>/<donation uuid>/<filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('donation-proofs', 'donation-proofs', false, 5242880,
        array['image/png', 'image/jpeg', 'image/webp', 'application/pdf']::text[])
on conflict (id) do update
set name = excluded.name, public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists donation_proofs_owner_or_admin_read on storage.objects;
create policy donation_proofs_owner_or_admin_read on storage.objects for select to authenticated
  using (
    bucket_id = 'donation-proofs'
    and (public.is_admin() or (
      (storage.foldername(name))[1] = (select auth.uid())::text
      and exists (
        select 1 from public.donations d
        where d.id::text = (storage.foldername(name))[2]
          and d.member_id = (select auth.uid())
      )
    ))
  );
drop policy if exists donation_proofs_owner_upload on storage.objects;
create policy donation_proofs_owner_upload on storage.objects for insert to authenticated
  with check (
    bucket_id = 'donation-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1 from public.donations d
      where d.id::text = (storage.foldername(name))[2]
        and d.member_id = (select auth.uid())
        and d.status in ('pending_payment', 'pending_verification', 'needs_review')
    )
  );
