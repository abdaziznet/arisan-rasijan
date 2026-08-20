# Deploy Database — Bani Rasijan

Script ini menerjemahkan `DATABASE_SCHEMA.md` menjadi migration SQL siap jalan di Supabase, dalam 8 file berurutan di folder `migrations/`.

```
migrations/
├── 001_extensions_and_helpers.sql   # extension + fungsi is_admin()
├── 002_tables.sql                   # semua 14 tabel
├── 003_indexes.sql                  # index untuk kolom FK yang sering di-query
├── 004_functions_triggers.sql       # alokasi kas otomatis + auto-close voting
├── 005_gathering_vote_tally.sql     # RPC agregat tally voting (aman dari RLS)
├── 006_rls_policies.sql             # RLS untuk semua tabel
├── 007_seed_settings.sql            # default app_settings
└── 008_storage_buckets.sql          # bucket avatars & event-photos + policy
```

**Urutan ini penting** — jangan dijalankan acak. Tabel harus ada dulu sebelum index/trigger/RLS dibuat, dan `app_settings` harus ada isinya sebelum policy `gathering_votes` yang membaca dari situ dipakai.

---

## Opsi A — Supabase CLI (direkomendasikan)

Paling aman untuk kerja tim & tracking history perubahan schema.

```bash
# 1. Install Supabase CLI (jika belum)
npm install -g supabase

# 2. Login & link ke project Supabase kamu
supabase login
supabase link --project-ref <project-ref-kamu>

# 3. Copy semua file di migrations/ ke folder migration project kamu
#    (Supabase CLI mengharuskan format nama <timestamp>_nama.sql,
#    jadi rename tiap file dengan menambah timestamp di depan, contoh:
#    20260812000001_extensions_and_helpers.sql)
cp migrations/*.sql supabase/migrations/

# 4. Push migration ke database remote
supabase db push
```

## Opsi B — SQL Editor di Supabase Dashboard

Lebih cepat untuk testing awal / project solo tanpa CLI.

1. Buka **Supabase Dashboard → SQL Editor**
2. Buka file `001_extensions_and_helpers.sql`, copy seluruh isinya, paste ke editor, klik **Run**
3. Ulangi untuk `002` sampai `008` **secara berurutan** — tunggu tiap file sukses sebelum lanjut ke berikutnya
4. Kalau ada error di tengah jalan, cek pesan error dulu sebelum lanjut — biasanya karena ada file sebelumnya yang belum ke-run sempurna

---

## Setelah Migration Selesai

1. **Cek Security setting project** (Project Settings → Data API → Security), samakan dengan rekomendasi kita sebelumnya:
   - ✅ Enable Data API
   - ☐ Automatically expose new tables (**matikan**)
   - ✅ Enable automatic RLS
2. **Verifikasi RLS aktif** di semua tabel: Dashboard → Table Editor → tiap tabel harus menampilkan badge "RLS enabled"
3. **Buat admin pertama secara manual** — karena tidak ada admin saat awal, setelah user pertama daftar via magic link, jalankan sekali di SQL Editor:
   ```sql
   update public.profiles set role = 'admin' where id = '<uuid-user-pertama>';
   ```
4. **Deploy Edge Functions** (belum termasuk di sini) — `generate-invite-code`, `redeem-invite-code`, `revoke-invite-code` sesuai kontrak di `ARCHITECTURE.md` bagian 5.1, dan logic kocokan sesuai bagian 5.2

---

## Catatan Perbaikan

Saat menulis migration ini, ditemukan 1 hal di `DATABASE_SCHEMA.md` (2.15) yang perlu dikoreksi: `gathering_vote_tally` awalnya dirancang sebagai `VIEW`, tapi `VIEW` biasa **tidak bypass RLS** dari tabel `gathering_votes` — hasil agregatnya akan salah untuk anggota biasa saat voting disembunyikan. Sudah diperbaiki menjadi `SECURITY DEFINER` RPC function (`005_gathering_vote_tally.sql`) yang aman dipanggil semua anggota tanpa membocorkan siapa memilih apa. `DATABASE_SCHEMA.md` dan `ARCHITECTURE.md` sudah diupdate mengikuti perbaikan ini.