-- Generated columns are not populated in NEW during BEFORE triggers.
-- Comparing NEW.payment_amount to OLD.payment_amount therefore rejects every
-- member update, even though payment_amount is derived and cannot be edited.
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

revoke all on function public.guard_member_donation_update() from public, anon, authenticated;
