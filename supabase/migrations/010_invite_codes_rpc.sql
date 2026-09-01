-- ============================================================
-- 010: Invite Codes Management RPC
-- Memungkinkan Admin men-generate kode undangan langsung dari App
-- dan Calon Anggota me-redeem kode untuk mengaktifkan profil.
-- ============================================================

-- 1. Function untuk Admin Generate Invite Code
create or replace function public.generate_invite_code(
  p_custom_code text default null,
  p_max_uses integer default 1,
  p_expires_days integer default 30
)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
  v_hash text;
begin
  -- 1. Validasi Pemanggil adalah Admin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat membuat kode undangan.';
  end if;

  -- 2. Tentukan kode (custom atau auto-generate)
  if p_custom_code is not null and trim(p_custom_code) <> '' then
    v_code := upper(trim(p_custom_code));
  else
    -- Generate kode acak 8 karakter: BANI-XXXX
    v_code := 'BANI-' || upper(substr(md5(random()::text), 1, 4));
  end if;

  -- 3. Hash kode dengan SHA-256
  v_hash := encode(digest(v_code, 'sha256'), 'hex');

  -- 4. Simpan ke database
  insert into public.invite_codes (
    code_hash,
    created_by,
    expires_at,
    max_uses,
    used_count,
    is_revoked
  )
  values (
    v_hash,
    auth.uid(),
    now() + (p_expires_days || ' days')::interval,
    p_max_uses,
    0,
    false
  );

  return v_code;
end;
$$;

-- 2. Function untuk User Baru Redeem Kode & Lengkapi Profil Sekaligus
create or replace function public.redeem_invite_code(
  p_code text,
  p_full_name text,
  p_phone_number text default null,
  p_address text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid;
  v_hash text;
  v_invite record;
begin
  v_user_id := auth.uid();

  -- 1. Pastikan user terautentikasi (Google Sign-In)
  if v_user_id is null then
    raise exception 'User harus login terlebih dahulu.';
  end if;

  -- 2. Cek apakah profil sudah ada
  if exists (select 1 from public.profiles where id = v_user_id) then
    return jsonb_build_object('success', true, 'message', 'Profil sudah aktif.');
  end if;

  -- 3. Hash kode inputan
  v_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');

  -- 4. Cari kode undangan yang valid
  select * into v_invite
  from public.invite_codes
  where code_hash = v_hash
    and is_revoked = false
    and expires_at > now()
    and used_count < max_uses
  for update;

  if not found then
    raise exception 'Kode undangan tidak valid atau sudah kedaluwarsa.';
  end if;

  -- 5. Inkremen used_count
  update public.invite_codes
  set used_count = used_count + 1
  where id = v_invite.id;

  -- 6. Buat row di tabel profiles
  insert into public.profiles (
    id,
    full_name,
    phone_number,
    address,
    role,
    is_active
  )
  values (
    v_user_id,
    trim(p_full_name),
    nullif(trim(p_phone_number), ''),
    nullif(trim(p_address), ''),
    'member',
    true
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Pendaftaran berhasil. Selamat bergabung di keluarga Bani Rasijan!'
  );
end;
$$;
