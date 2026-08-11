# Database Schema
## Aplikasi Arisan Keluarga (Supabase / PostgreSQL)

**Versi:** 1.0
**Terkait:** `PRD.md`, `ARCHITECTURE.md`

---

## 1. Ringkasan Tabel

| Tabel | Fungsi |
|---|---|
| `profiles` | Data anggota keluarga (extend dari `auth.users`) |
| `arisan_periods` | Data tiap periode arisan (2 bulan sekali) |
| `payments` | Pencatatan status iuran per anggota per periode |
| `donations` | Pencatatan donasi opsional per periode |
| `draws` | Histori hasil kocokan per periode |
| `event_checklist` | Checklist rundown acara per periode |
| `event_photos` | Galeri foto dokumentasi per periode |
| `notifications` | Log reminder/pengumuman (opsional) |
| `app_settings` | Konfigurasi umum aplikasi (misal: persentase potongan kas gathering) |
| `fund_ledger` | Buku besar kas gathering (pemasukan dari alokasi iuran & pengeluaran untuk event) |
| `gathering_events` | Data event gathering keluarga (didanai dari kas bersama) |
| `gathering_poll_options` | Opsi tujuan gathering yang dibuat admin untuk voting |
| `gathering_votes` | Suara tiap anggota untuk voting gathering |

Catatan: karena aplikasi ini untuk **satu grup keluarga saja** (bukan multi-tenant), tidak diperlukan tabel `families`/`groups` terpisah kecuali kamu ingin app ini reusable untuk lebih dari satu keluarga di kemudian hari.

---

## 2. Detail Tabel

### 2.1 `profiles`
Menyimpan data tambahan anggota, terhubung 1:1 ke `auth.users` (yang menangani email & auth).

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK, FK → `auth.users.id`) | ID user dari Supabase Auth |
| `full_name` | `text` | Nama lengkap |
| `phone_number` | `text`, nullable | No HP (opsional, bukan untuk auth) |
| `address` | `text`, nullable | Alamat rumah (berguna saat jadi tuan rumah) |
| `photo_url` | `text`, nullable | URL foto profil (Supabase Storage) |
| `role` | `text`, default `'member'` | `'admin'` atau `'member'` |
| `is_active` | `boolean`, default `true` | Status keanggotaan aktif |
| `has_won_before` | `boolean`, default `false` | Penanda pernah menang (untuk opsi exclude) |
| `created_at` | `timestamptz`, default `now()` | Waktu bergabung |

**RLS Policy:**
- `SELECT`: semua user yang sudah login (`auth.uid() IS NOT NULL`) boleh melihat semua profil dalam grup
- `UPDATE`: user hanya boleh update baris miliknya sendiri (`id = auth.uid()`), kecuali admin yang boleh update semua

---

### 2.2 `arisan_periods`
Satu baris = satu siklus arisan (2 bulan).

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | ID periode |
| `period_number` | `integer` | Urutan periode (1, 2, 3, ...) |
| `event_date` | `date` | Tanggal pelaksanaan |
| `host_id` | `uuid` (FK → `profiles.id`) | Tuan rumah periode ini (= pemenang periode sebelumnya) |
| `host_address` | `text`, nullable | Alamat tuan rumah (snapshot, jaga-jaga kalau profil berubah) |
| `contribution_amount` | `numeric`, nullable | Nominal iuran wajib periode ini |
| `status` | `text`, default `'upcoming'` | `'upcoming'`, `'ongoing'`, `'completed'` |
| `winner_id` | `uuid` (FK → `profiles.id`), nullable | Diisi setelah kocokan selesai |
| `total_collected` | `numeric`, nullable | Total uang terkumpul (iuran, dihitung otomatis/manual) |
| `created_at` | `timestamptz`, default `now()` | |

**RLS Policy:**
- `SELECT`: semua anggota grup
- `INSERT`/`UPDATE`: hanya `role = 'admin'`

---

### 2.3 `payments`
Status iuran tiap anggota per periode.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`) | |
| `member_id` | `uuid` (FK → `profiles.id`) | |
| `amount` | `numeric` | Nominal yang dibayar |
| `payment_method` | `text`, nullable | `'cash'` / `'transfer'` |
| `status` | `text`, default `'unpaid'` | `'unpaid'`, `'paid'` |
| `paid_at` | `timestamptz`, nullable | |
| `recorded_by` | `uuid` (FK → `profiles.id`) | Admin yang mencatat |
| `allocated_to_fund` | `numeric`, default `0` | Nominal dari pembayaran ini yang dipotong & masuk ke kas gathering (dihitung otomatis dari `app_settings`) |

**Constraint:** `UNIQUE(period_id, member_id)` — satu anggota hanya punya 1 baris pembayaran per periode.

**RLS Policy:**
- `SELECT`: semua anggota grup boleh lihat (transparansi)
- `INSERT`/`UPDATE`: hanya admin

---

### 2.4 `donations`
Donasi opsional, terpisah dari iuran wajib.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`) | |
| `member_id` | `uuid` (FK → `profiles.id`) | |
| `amount` | `numeric` | |
| `note` | `text`, nullable | Catatan/tujuan donasi (jika ada) |
| `created_at` | `timestamptz`, default `now()` | |

**RLS Policy:** sama seperti `payments`.

---

### 2.5 `draws`
Histori hasil kocokan — inti transparansi aplikasi.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`, unique) | 1 kocokan per periode |
| `eligible_member_ids` | `uuid[]` | Daftar anggota yang ikut diundi (setelah exclude, jika ada) |
| `winner_id` | `uuid` (FK → `profiles.id`) | Hasil undian |
| `draw_method` | `text`, default `'random'` | Metode (untuk audit, misal `'random'` atau `'manual_override'`) |
| `conducted_by` | `uuid` (FK → `profiles.id`) | Admin yang menjalankan kocokan |
| `conducted_at` | `timestamptz`, default `now()` | |

**RLS Policy:**
- `SELECT`: semua anggota grup (transparansi hasil kocokan)
- `INSERT`: hanya admin, dan idealnya lewat **Edge Function** (bukan langsung dari client) agar logika random & exclude tidak bisa dimanipulasi dari sisi app

---

### 2.6 `event_checklist`
Rundown acara yang bisa dicentang real-time.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`) | |
| `step_name` | `text` | Contoh: `'Kumpul'`, `'Yasin & Sholawat'`, `'Makan'`, `'Kocokan'`, `'Serah Terima Uang'`, `'Foto Bersama'`, `'Penutupan'` |
| `step_order` | `integer` | Urutan tahap |
| `is_completed` | `boolean`, default `false` | |
| `completed_at` | `timestamptz`, nullable | |

**RLS Policy:** `SELECT` semua anggota; `UPDATE` hanya admin.

---

### 2.7 `event_photos`
Galeri dokumentasi.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`) | |
| `photo_url` | `text` | URL di Supabase Storage bucket |
| `uploaded_by` | `uuid` (FK → `profiles.id`) | |
| `uploaded_at` | `timestamptz`, default `now()` | |

**RLS Policy:** `SELECT` semua anggota; `INSERT` semua anggota (agar siapa saja bisa upload foto bersama, tidak harus admin).

---

### 2.8 `notifications` *(opsional, fase 2)*

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `period_id` | `uuid` (FK → `arisan_periods.id`), nullable | |
| `title` | `text` | |
| `body` | `text` | |
| `sent_at` | `timestamptz`, nullable | |
| `type` | `text` | `'reminder_h7'`, `'reminder_h1'`, `'announcement'` |

---

### 2.9 `app_settings`
Menyimpan konfigurasi umum aplikasi dalam bentuk key-value, termasuk aturan potongan kas gathering.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `key` | `text` (PK) | Contoh: `'gathering_fund_percentage'` |
| `value` | `text` | Contoh: `'10'` (artinya 10% dari tiap iuran) |
| `updated_by` | `uuid` (FK → `profiles.id`), nullable | |
| `updated_at` | `timestamptz`, default `now()` | |

**RLS Policy:** `SELECT` semua anggota (agar aturan potongan transparan); `UPDATE` hanya admin.

---

### 2.10 `fund_ledger`
Buku besar (ledger) kas gathering — mencatat semua pemasukan (dari potongan iuran) dan pengeluaran (untuk event gathering). **Total kas gathering saat ini** = `SUM(amount)` dari tabel ini.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `type` | `text` | `'contribution_allocation'` (masuk, dari potongan iuran), `'gathering_expense'` (keluar, dipakai untuk event), `'adjustment'` (koreksi manual admin) |
| `amount` | `numeric` | Bernilai positif untuk pemasukan, negatif untuk pengeluaran |
| `period_id` | `uuid` (FK → `arisan_periods.id`), nullable | Diisi jika baris ini berasal dari alokasi iuran periode tertentu |
| `gathering_event_id` | `uuid` (FK → `gathering_events.id`), nullable | Diisi jika baris ini adalah pengeluaran untuk event gathering tertentu |
| `description` | `text`, nullable | Catatan tambahan |
| `created_by` | `uuid` (FK → `profiles.id`) | |
| `created_at` | `timestamptz`, default `now()` | |

**RLS Policy:** `SELECT` semua anggota (transparansi kas bersama); `INSERT` hanya admin (idealnya baris `'contribution_allocation'` dibuat otomatis via trigger saat `payments.status` diubah jadi `'paid'`, bukan input manual).

---

### 2.11 `gathering_events`
Data event gathering keluarga yang didanai dari kas bersama.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `title` | `text` | Contoh: `'Gathering Keluarga 2026'` |
| `status` | `text`, default `'voting'` | `'voting'`, `'decided'`, `'completed'`, `'cancelled'` |
| `winning_option_id` | `uuid` (FK → `gathering_poll_options.id`), nullable | Diisi otomatis setelah voting ditutup |
| `event_date` | `date`, nullable | Ditetapkan admin setelah opsi terpilih |
| `fund_used` | `numeric`, nullable | Nominal kas yang dipakai untuk event ini |
| `created_by` | `uuid` (FK → `profiles.id`) | Admin pembuat |
| `created_at` | `timestamptz`, default `now()` | |
| `closed_at` | `timestamptz`, nullable | Waktu voting otomatis ditutup |

**RLS Policy:** `SELECT` semua anggota; `INSERT`/`UPDATE` hanya admin.

---

### 2.12 `gathering_poll_options`
Opsi tujuan gathering yang dibuat admin untuk satu event.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `gathering_event_id` | `uuid` (FK → `gathering_events.id`) | |
| `option_label` | `text` | Contoh: `'Wisata ke Bandung'` |
| `created_at` | `timestamptz`, default `now()` | |

**RLS Policy:** `SELECT` semua anggota; `INSERT` hanya admin, hanya boleh menambah opsi selama `gathering_events.status = 'voting'`.

---

### 2.13 `gathering_votes`
Suara tiap anggota untuk satu event gathering.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` (PK) | |
| `gathering_event_id` | `uuid` (FK → `gathering_events.id`) | |
| `option_id` | `uuid` (FK → `gathering_poll_options.id`) | Opsi yang dipilih |
| `member_id` | `uuid` (FK → `profiles.id`) | Anggota yang memilih |
| `voted_at` | `timestamptz`, default `now()` | |

**Constraint:** `UNIQUE(gathering_event_id, member_id)` — satu anggota hanya boleh vote 1x per event (mencegah vote ganda).

**RLS Policy:**
- `SELECT`: semua anggota boleh lihat siapa vote apa (transparansi), atau bisa dibatasi hanya admin jika keluarga ingin voting rahasia — sesuaikan kesepakatan
- `INSERT`: anggota hanya boleh insert baris untuk dirinya sendiri (`member_id = auth.uid()`), dan hanya jika `gathering_events.status = 'voting'`
- Tidak ada `UPDATE`/`DELETE` — vote bersifat final setelah submit

**Logika penutupan voting otomatis:** setiap kali ada `INSERT` baru ke `gathering_votes`, jalankan pengecekan (lewat **trigger** atau **Edge Function**): jika `COUNT(gathering_votes) WHERE gathering_event_id = X` sudah sama dengan jumlah anggota aktif (`COUNT(profiles) WHERE is_active = true`), maka:
1. Hitung opsi dengan suara terbanyak → set `gathering_events.winning_option_id`
2. Update `gathering_events.status = 'decided'`
3. Set `gathering_events.closed_at = now()`

---

## 3. Relasi Antar Tabel (Ringkasan)

```
auth.users (Supabase built-in)
   └── profiles (1:1)
          ├── arisan_periods.host_id (1:N)
          ├── arisan_periods.winner_id (1:N)
          ├── payments.member_id (1:N)
          ├── donations.member_id (1:N)
          ├── draws.winner_id (1:N)
          └── event_photos.uploaded_by (1:N)

arisan_periods
   ├── payments (1:N) ── allocated_to_fund ──► fund_ledger (1:N, type='contribution_allocation')
   ├── donations (1:N)
   ├── draws (1:1)
   ├── event_checklist (1:N)
   └── event_photos (1:N)

gathering_events
   ├── gathering_poll_options (1:N)
   ├── gathering_votes (1:N, via gathering_poll_options)
   └── fund_ledger (1:N, type='gathering_expense')
```

---

## 4. Catatan Implementasi RLS

Karena ini data keuangan keluarga, prinsip RLS yang dipakai:

1. **Semua tabel** hanya bisa diakses oleh user yang sudah login (`auth.uid() IS NOT NULL`) — tidak ada akses publik/anonim
2. **Read (SELECT)** umumnya terbuka untuk semua anggota grup — sesuai prinsip transparansi arisan (semua boleh lihat siapa bayar, siapa menang)
3. **Write (INSERT/UPDATE)** untuk data keuangan & kocokan dibatasi hanya untuk `role = 'admin'`
4. Proses **kocokan** sebaiknya dieksekusi lewat **Supabase Edge Function** (server-side), bukan langsung dari Flutter client, supaya random logic & aturan exclude tidak bisa dimanipulasi oleh siapa pun termasuk admin secara tidak sengaja
5. Proses **penutupan voting gathering otomatis** dan **penghitungan opsi pemenang** juga sebaiknya dijalankan lewat **database trigger** atau **Edge Function**, bukan logic di client, agar hasil voting tidak bisa direkayasa dan konsisten meski beberapa anggota vote bersamaan (race condition)

---

## 5. Storage Buckets (Supabase Storage)

| Bucket | Isi | Akses |
|---|---|---|
| `avatars` | Foto profil anggota | Public read, authenticated write (own file) |
| `event-photos` | Foto dokumentasi tiap periode acara | Authenticated read & write (semua anggota grup) |
