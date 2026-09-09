-- RPC: run_draw (v2)
-- Perbaikan: tambah param p_conducted_by uuid.
-- Edge Function memanggil RPC via service_role key, sehingga auth.uid() di dalam
-- RPC selalu NULL (tidak ada request JWT). Sebelumnya insert ke draws gagal dengan
-- NOT NULL violation pada kolom conducted_by.
-- v2 menerima conducted_by dari caller (admin yang terautentikasi) dan fallback
-- ke auth.uid() jika param NULL (mis. admin menjalankan via SQL editor terautentikasi).

create or replace function run_draw(p_period_id uuid, p_conducted_by uuid default null)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw_id        uuid;
  v_winner_id      uuid;
  v_period_number  integer;
  v_contribution   numeric;
  v_eligible_ids   uuid[];
  v_past_winners   uuid[];
  v_active_members uuid[];
  v_next_period_number integer;
  v_next_event_date    date;
  v_winner_name    text;
  v_total_collected numeric;
  v_conducted_by   uuid;
begin
  -- 0. Resolve conducted_by: param pemenang jika diberikan, else auth.uid()
  v_conducted_by := coalesce(p_conducted_by, auth.uid());

  -- 1. Cek idempoten: draw sudah ada untuk periode ini?
  select id into v_draw_id
  from draws
  where period_id = p_period_id;

  if v_draw_id is not null then
    -- Kembalikan data draw yang sudah ada
    select row_to_json(d)
    into strict v_draw_id
    from (
      select dr.id, dr.period_id, dr.winner_id, dr.conducted_at as created_at,
             p.full_name as winner_name,
             ap.total_collected
      from draws dr
      join profiles p on p.id = dr.winner_id
      join arisan_periods ap on ap.id = dr.period_id
      where dr.id = v_draw_id
    ) d;
    return v_draw_id::json;
  end if;

  -- 2. Ambil data periode
  select period_number, contribution_amount
  into v_period_number, v_contribution
  from arisan_periods
  where id = p_period_id;

  if not found then
    raise exception 'Periode tidak ditemukan: %', p_period_id;
  end if;

  -- 3. Hitung total terkumpul
  select coalesce(sum(amount), 0)
  into v_total_collected
  from payments
  where period_id = p_period_id and status = 'paid';

  -- 4. Ambil semua anggota aktif
  select array_agg(id) into v_active_members
  from profiles
  where is_active = true;

  -- 5. Ambil pemenang sebelumnya
  select array_agg(winner_id) into v_past_winners
  from arisan_periods
  where winner_id is not null;

  -- 6. Tentukan kandidat eligible (exclude past winners, kecuali semua sudah menang)
  if v_past_winners is null then
    v_eligible_ids := v_active_members;
  elsif (select count(*) from unnest(v_active_members) m
         where m = any(v_past_winners)) >= array_length(v_active_members, 1) then
    -- Semua sudah pernah menang: reset siklus
    v_eligible_ids := v_active_members;
  else
    select array_agg(m) into v_eligible_ids
    from unnest(v_active_members) m
    where m <> all(v_past_winners);
  end if;

  if v_eligible_ids is null or array_length(v_eligible_ids, 1) = 0 then
    raise exception 'Tidak ada kandidat eligible untuk kocokan.';
  end if;

  -- 7. Pilih pemenang secara acak
  select v_eligible_ids[1 + floor(random() * array_length(v_eligible_ids, 1))::int]
  into v_winner_id;

  -- 8. Simpan draw
  insert into draws (period_id, eligible_member_ids, winner_id, draw_method, conducted_by, conducted_at)
  values (
    p_period_id,
    v_eligible_ids,
    v_winner_id,
    'random',
    v_conducted_by,
    now()
  )
  returning id into v_draw_id;

  -- 9. Update winner_id dan total_collected di periode ini
  update arisan_periods
  set winner_id = v_winner_id,
      total_collected = v_total_collected,
      status = 'completed'
  where id = p_period_id;

  -- 10. Update has_won_before di profiles
  update profiles
  set has_won_before = true
  where id = v_winner_id;

  -- 11. Buat periode berikutnya (2 bulan setelah event_date)
  v_next_period_number := v_period_number + 1;
  select event_date + interval '2 months' into v_next_event_date
  from arisan_periods where id = p_period_id;

  insert into arisan_periods (period_number, event_date, host_id, status)
  values (v_next_period_number, v_next_event_date, v_winner_id, 'upcoming')
  on conflict do nothing;

  -- 12. Ambil nama pemenang
  select full_name into v_winner_name from profiles where id = v_winner_id;

  -- 13. Return result
  return json_build_object(
    'id', v_draw_id,
    'period_id', p_period_id,
    'winner_id', v_winner_id,
    'winner_name', v_winner_name,
    'total_collected', v_total_collected,
    'created_at', now()
  );
end;
$$;

-- Grant execute hanya ke service_role (dipanggil via Edge Function)
revoke execute on function run_draw(uuid, uuid) from public;
revoke execute on function run_draw(uuid, uuid) from authenticated;
grant execute on function run_draw(uuid, uuid) to service_role;

-- Fungsi lama signature (uuid) dianggap usang; jika sudah ter-apply, drop supaya
-- tidak ambigu. (create or replace function dengan arg default murni tidak
-- mengubah signature lama.)
drop function if exists run_draw(uuid);