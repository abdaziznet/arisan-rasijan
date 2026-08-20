-- ============================================================
-- 001: Extensions & Helper Functions
-- Bani Rasijan — Arisan Keluarga
-- ============================================================

-- PostgreSQL 13+ di Supabase sudah memiliki gen_random_uuid() secara bawaan.
-- Ekstensi ini opsional, tetapi disarankan ditempatkan di skema 'extensions'.
create extension if not exists pgcrypto schema extensions;

-- Helper RLS untuk mengecek role admin pengguna
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Berikan izin eksekusi ke pengguna terautentikasi
grant execute on function public.is_admin() to authenticated;