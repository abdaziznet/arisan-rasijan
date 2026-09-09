-- ============================================================
-- 013: Fix fund allocation trigger — use allocated_to_fund
--
-- Masalah: trigger fn_allocate_payment_to_fund membaca
-- app_settings.gathering_fund_percentage (desain persentase
-- lama, hanya ada di seed 007) padahal app sekarang memakai
-- gathering_fund_amount (nilai tetap rupiah, ditulis lewat
-- Pengaturan Admin → Kas Gathering). Karena key itu tidak ada
-- di DB, coalesce(v_percentage,0) = 0 → alokasi 0.00 dan
-- fund_ledger.amount selalu 0 meski status payment sudah paid.
--
-- Fix: trigger memakai new.allocated_to_fund (angka yang sudah
-- dihitung app: iuran − gathering_fund_amount), dan menjadikan
-- trigger satu-satunya penulis fund_ledger. Alokasi 0.00 → tidak
-- ada baris ledger (hindari row kosong tak berguna).
-- ============================================================

create or replace function public.fn_allocate_payment_to_fund()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_allocation numeric;
begin
  if new.status = 'paid' and (tg_op = 'INSERT' or old.status is distinct from 'paid') then
    v_allocation := round(coalesce(new.allocated_to_fund, 0), 2);

    -- Supaya jumlah kas gathering di payments.allocated_to_fund
    -- dan fund_ledger selalu selaras.
    new.allocated_to_fund := v_allocation;

    if v_allocation > 0 then
      insert into public.fund_ledger (type, amount, period_id, description, created_by)
      values (
        'contribution_allocation',
        v_allocation,
        new.period_id,
        'Alokasi otomatis dari iuran anggota',
        coalesce(new.recorded_by, new.member_id)
      );
    end if;
  end if;
  return new;
end;
$$;

-- Drop trigger lama dan recreate (func di atas sudah updated; trigger
-- tetap terpasang, recreate eksplisit untuk kejelasan + tak ada double).
drop trigger if exists trg_allocate_payment_to_fund on public.payments;
create trigger trg_allocate_payment_to_fund
before insert or update on public.payments
for each row
execute function public.fn_allocate_payment_to_fund();

-- Hapus setting legacy yang tak dipakai app lagi.
delete from public.app_settings where key = 'gathering_fund_percentage';

-- --------------------------------------------------------------
-- Backfill: pastikan setiap payment paid punya SATU baris ledger
-- dengan amount = allocated_to_fund yang benar (bukan 0).
-- --------------------------------------------------------------

-- 1) Perbaiki amount baris ledger contribution_allocation yang 0
--    menjadi allocated_to_fund dari payment terkait (klausa
--    created_by = member_id menjaga agar tidak menimpa alokasi
--    donasi/gathering lain di periode yang sama).
update public.fund_ledger l
set amount = coalesce(p.allocated_to_fund, 0)
from public.payments p
where l.type = 'contribution_allocation'
  and (l.amount is null or l.amount = 0)
  and l.period_id = p.period_id
  and coalesce(l.created_by, gen_random_uuid()::text::uuid) = coalesce(p.member_id, gen_random_uuid()::text::uuid);

-- 2) Hapus baris ledger 0 yang TIDAK punya payment paid terkait
--    (contoh: created_by admin, bukan member) supaya tidak tercatat
--    sebagai kas gathering.
delete from public.fund_ledger l
where l.type = 'contribution_allocation'
  and (l.amount is null or l.amount = 0)
  and not exists (
    select 1 from public.payments p
    where p.status = 'paid'
      and p.period_id = l.period_id
      and p.member_id = l.created_by
  );

-- 3) Baris ledger yang benar untuk payment paid yang BELUM punya
--    ledger (mis. addPayment lama yang insert payments tapi ledger
--    di-trigger hanya untuk satu baris).
insert into public.fund_ledger (type, amount, period_id, description, created_by)
select
  'contribution_allocation',
  p.allocated_to_fund,
  p.period_id,
  'Alokasi otomatis dari iuran anggota',
  p.member_id
from public.payments p
where p.status = 'paid'
  and p.allocated_to_fund > 0
  and not exists (
    select 1 from public.fund_ledger l
    where l.type = 'contribution_allocation'
      and l.period_id = p.period_id
      and l.created_by = p.member_id
  );