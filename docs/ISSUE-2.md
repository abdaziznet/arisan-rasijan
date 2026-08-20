# ISSUE: Migrasi Authentication — Supabase Auth (Magic Link) → Firebase Auth (Google Sign-In)

**Status:** Draft — menunggu review & approval developer sebelum implementasi
**Scope:** HANYA authentication. Database core **tetap Supabase** (Postgres, RLS, Storage, Realtime, Edge Functions tidak diganti)
**Terkait:** `PRD.md`, `DATABASE_SCHEMA.md`, `ARCHITECTURE.md`, `DESIGN_SYSTEM.md`

---

## ⚠️ Catatan Lingkungan (baca dulu)

Task ini diminta dikerjakan menggunakan skill dari `.agents/skills` dan `.claude/skills` di project kamu. Di sandbox chat ini, folder tersebut **tidak tersedia** — hanya ada dokumen yang sudah kita buat sebelumnya. Bagian implementasi kode (Edge Function, migration SQL, Flutter) di bawah ini ditulis sebagai **rencana kerja siap pakai**, tapi eksekusi sebaiknya dilakukan lewat Claude Code di repo asli kamu, di mana skill-skill tsb bisa dibaca. Saya tandai tiap bagian yang butuh eksekusi lokal dengan 🛠️.

---

## 1. Ringkasan Perubahan

| Sebelum | Sesudah |
|---|---|
| Login via Supabase Auth — Email Magic Link/OTP | Login via **Firebase Auth — Google Sign-In** (user tinggal pilih akun Gmail, tidak perlu isi kode/klik link email) |
| User tercatat di `auth.users` (skema internal Supabase) | User tercatat di **Firebase Authentication**, TIDAK ada lagi di `auth.users` Supabase |
| RLS Supabase pakai `auth.uid()` bawaan | RLS Supabase tetap dipakai, tapi lewat skema **Third-Party Auth** resmi Supabase untuk Firebase |
| Database, Storage, Realtime, Edge Function | **Tidak berubah** — tetap 100% Supabase |

---

## 2. Motivasi

- Google Sign-In lebih ringkas untuk anggota keluarga — cukup pilih akun Gmail, tidak perlu buka email terpisah untuk klik magic link atau salin kode OTP
- Sudah familiar untuk hampir semua orang yang punya HP Android (akun Google sudah login di device)

---

## 3. Dasar Teknis: Supabase Third-Party Auth untuk Firebase

Supabase punya fitur resmi **Third-Party Auth** yang mempercayai JWT dari Firebase, tanpa perlu Supabase Auth sama sekali. <cite index="2-1">Caranya: menambahkan integrasi untuk menghubungkan project Supabase dengan project Firebase menggunakan Project ID dari Firebase Console, lalu menambahkan integrasi Third-party Auth baru di pengaturan Authentication project.</cite> <cite index="2-1">Semua user wajib diberi custom claim `role: 'authenticated'`, dan Supabase client dikonfigurasi dengan fungsi `accessToken` yang mengembalikan JWT dari Firebase Auth user yang sedang login.</cite>

Ini artinya: kita **tidak perlu bikin backend auth sendiri**, tinggal pasang integrasi resmi dan Supabase akan mempercayai token dari Firebase, sama seperti mempercayai token dari Supabase Auth sendiri.

<cite index="11-1">Kalau ada JWT dikirim dari project Firebase yang belum terdaftar, role `anon` yang akan dipakai saat eksekusi query Postgres — bukan `authenticated` — sehingga otomatis dibatasi RLS.</cite>

---

## 4. 🔴 KONFLIK / BREAKING CHANGE — WAJIB DIREVIEW DEVELOPER SEBELUM LANJUT

Ini bagian paling penting dari issue ini. **Jangan langsung implementasi sebelum poin-poin ini di-approve.**

### 🔴 Konflik #1 — Firebase UID BUKAN format UUID

Ini akar dari hampir semua breaking change di bawah. Firebase Auth memberi tiap user sebuah UID berupa string alfanumerik ~28 karakter (contoh: `Kgy1YMg2c6E8spXkN8zUWL40PUAktX0E`) — **bukan** UUID v4 seperti yang dipakai `auth.users.id` Supabase.

Sementara itu, fungsi bawaan `auth.uid()` di Postgres Supabase secara internal **melakukan cast eksplisit ke tipe `uuid`** terhadap claim `sub` dari JWT. Kalau `sub`-nya adalah Firebase UID (bukan format UUID), pemanggilan `auth.uid()` akan **gagal dengan error `invalid input syntax for type uuid`**.

Ini bukan teori — sudah jadi laporan bug nyata di Supabase saat dipakai dengan sub claim non-UUID: <cite index="10-1">ketika JWT sub claim bukan UUID, listing file di Storage gagal dengan error "invalid input syntax for type uuid", meski upload file (yang hanya menyimpan owner_id sebagai string) tetap berhasil.</cite>

**Dampak ke schema kita:** SEMUA kolom berikut yang sekarang bertipe `uuid` dan mereferensikan `profiles.id` (yang selama ini = `auth.users.id`) **harus diubah tipenya jadi `text`**:

| Tabel | Kolom terdampak |
|---|---|
| `profiles` | `id` (primary key) |
| `arisan_periods` | `host_id`, `winner_id` |
| `payments` | `member_id`, `recorded_by` |
| `donations` | `member_id` |
| `draws` | `winner_id`, `conducted_by`, dan isi array `eligible_member_ids` |
| `event_photos` | `uploaded_by` |
| `app_settings` | `updated_by` |
| `fund_ledger` | `created_by` |
| `gathering_events` | `created_by` |
| `gathering_votes` | `member_id` |
| `invite_codes` | `created_by`, `revoked_by` |

**Pilihan yang perlu di-approve:**

- **Opsi A (direkomendasikan):** ubah semua kolom di atas dari `uuid` → `text`, isi dengan Firebase UID apa adanya. Konsisten, tidak ada mapping ganda.
- **Opsi B:** pertahankan `profiles.id` sebagai `uuid` biasa (generate baru, tidak terkait Firebase), tambah kolom terpisah `firebase_uid text unique`. Konsekuensi: hampir semua RLS policy yang sekarang bentuknya `member_id = auth.uid()` harus diubah jadi subquery ke `profiles` lewat `firebase_uid` — lebih rumit dan lebih lambat, tapi tipe `uuid` di tabel lain tetap konsisten dengan struktur lama.

> **Belum saya eksekusi ke schema — menunggu kamu pilih Opsi A atau B.** Draft SQL di bagian 6 di bawah saya tulis dengan asumsi **Opsi A**, tapi ditandai jelas supaya gampang di-adjust kalau kamu pilih Opsi B.

### 🔴 Konflik #2 — `auth.uid()` bawaan Supabase tidak bisa dipakai langsung

Karena masalah cast `::uuid` di atas, semua pemakaian `auth.uid()` di seluruh RLS policy (`006_rls_policies.sql`) dan fungsi `is_admin()` (`004_functions_triggers.sql`) berpotensi error. Perlu diganti ke ekspresi yang membaca claim `sub` sebagai teks langsung: `(auth.jwt() ->> 'sub')`, bukan `auth.uid()`.

**File yang terdampak:** `004_functions_triggers.sql` (`is_admin()`), `006_rls_policies.sql` (hampir seluruh policy), `008_storage_buckets.sql` (policy avatar & event-photos).

### 🔴 Konflik #3 — FK `profiles.id → auth.users(id)` harus dihapus

`auth.users` adalah tabel internal Supabase Auth. Karena user sekarang dikelola Firebase, tidak akan ada baris baru masuk ke `auth.users` sama sekali — FK ini akan selalu gagal untuk user baru. **Constraint ini wajib di-drop.**

### 🔴 Konflik #4 — Alur invite code harus didesain ulang (bukan cuma disesuaikan tipe data)

Alur lama: admin generate kode → calon anggota masukkan kode + email lewat Edge Function `redeem-invite-code` → kalau valid, sistem trigger `signInWithOtp` → anggota lanjut ke magic link.

Dengan Google Sign-In, user **langsung terautentikasi begitu memilih akun Google** — tidak ada jeda "masukkan kode dulu, baru dikirim link". Ini mengubah keputusan desain: validasi kode harus terjadi **di titik yang berbeda**. Dua opsi:

- **Opsi A:** Tampilkan layar "Masukkan kode undangan" **sebelum** tombol Google Sign-In muncul. Setelah kode divalidasi (Edge Function tetap dipanggil, tapi tanpa trigger OTP), baru tombol "Lanjut dengan Google" aktif. Setelah Google Sign-In sukses, panggil Edge Function kedua untuk "menyelesaikan" pendaftaran (create row `profiles`, increment `used_count` di `invite_codes`).
- **Opsi B:** Biarkan user Google Sign-In dulu, tapi row `profiles` **tidak dibuat** sampai mereka input kode undangan valid di layar berikutnya. User yang belum submit kode valid dianggap "belum aktif" dan tidak bisa akses fitur lain.

> **Perlu keputusan kamu** — saya rekomendasikan **Opsi A** (gate di depan) karena lebih jelas secara UX dan mencegah orang asing sempat login walau cuma sebentar. Belum saya tuliskan Edge Function-nya sampai ini dikonfirmasi.

### 🔴 Konflik #5 — Tidak ada lagi trigger otomatis pembuatan row `profiles`

Sebelumnya alur `profiles` dibuat setelah verifikasi magic link (dicek "kalau belum ada, arahkan ke flow lengkapi profil" — lihat `ARCHITECTURE.md` 5.1). Ini tetap berlaku secara konsep, hanya saja triggernya sekarang adalah **sukses Google Sign-In**, bukan verifikasi OTP. Perlu dipastikan Edge Function/klien Flutter yang membuat row `profiles` pertama kali menyimpan Firebase UID yang benar sebagai `id`.

---

## 5. Step-by-Step Konfigurasi Firebase (Pakai FlutterFire CLI)

Daripada add app Android/iOS manual satu-satu di Console (rawan salah masukin `applicationId`/Bundle ID), pakai **FlutterFire CLI** — tool resmi yang otomatis mendeteksi platform di project Flutter kamu dan mendaftarkannya ke Firebase Console untuk kamu. Ini juga generate 1 file `firebase_options.dart` untuk semua platform sekaligus.

1. **Buat project Firebase baru** (atau pakai yang sudah ada) di [console.firebase.google.com](https://console.firebase.google.com)
   - Nama project: `bani-rasijan` (atau sesuai preferensi)
2. **Install Firebase CLI & FlutterFire CLI** 🛠️:
   ```bash
   npm install -g firebase-tools
   firebase login

   dart pub global activate flutterfire_cli
   ```
3. **Jalankan `flutterfire configure` dari root project Flutter** 🛠️:
   ```bash
   flutterfire configure
   ```
   - Pilih project Firebase (`bani-rasijan`) yang sudah dibuat di step 1
   - Pilih platform yang mau didaftarkan: **Android** dan **iOS** (centang keduanya)
   - CLI ini otomatis: mendaftarkan app Android & iOS ke Firebase Console, download & taruh `google-services.json` (di `android/app/`) dan `GoogleService-Info.plist` (di `ios/Runner/`) di lokasi yang benar, generate `lib/firebase_options.dart`
   - **Tidak perlu klik "Add app" manual di Console sama sekali** — semua diurus CLI ini
4. **Aktifkan Google sebagai Sign-in Provider** (ini satu-satunya bagian yang tetap manual di Console, karena bukan bagian dari `flutterfire configure`):
   - Buka **Authentication → Sign-in method**
   - Pilih **Google**, toggle **Enable**
   - Isi "Project support email" (email kamu sebagai developer)
   - Simpan
5. **Ambil SHA-1 & SHA-256 fingerprint** untuk Android (wajib untuk Google Sign-In berfungsi — ini juga tidak otomatis dari `flutterfire configure`):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Copy SHA-1 & SHA-256 dari hasilnya, masukkan ke **Project Settings → Your apps → Android app → Add fingerprint**
6. **Catat Firebase Project ID** (bukan Project Number) dari **Project Settings → General** — ini yang akan dipakai di step Supabase Third-Party Auth
7. **(Wajib untuk RLS) Set custom claim `role: authenticated` ke semua user** — Firebase tidak menambahkan claim ini secara default, jadi perlu **Cloud Function** yang jalan setiap user baru dibuat:
   - Buka **Cloud Functions**, buat function `beforeUserCreated` (Auth Blocking Function) yang set custom claim:
     ```js
     exports.beforeUserCreated = beforeUserCreated((event) => {
       return {
         customClaims: { role: "authenticated" },
       };
     });
     ```
   - Deploy function ini lewat Firebase CLI (`firebase deploy --only functions`) — 🛠️ ini bagian yang perlu dikerjakan di repo asli
8. **Aktifkan Firebase Blaze plan** (pay-as-you-go) — Cloud Functions (termasuk Auth Blocking Functions) butuh plan ini, tidak jalan di Spark (free) plan. Cek dulu estimasi biaya di kalkulator Firebase — untuk skala keluarga kemungkinan tetap masuk free tier Blaze (ada quota gratis di dalamnya)

---

## 6. Step-by-Step Konfigurasi Supabase (Third-Party Auth)

1. Buka **Supabase Dashboard → Authentication → Third-Party Auth**
2. Klik **Add integration → Firebase**
3. Masukkan **Firebase Project ID** (dari step Firebase 5 di atas)
4. Simpan integrasi
5. (Opsional, kalau pakai Supabase CLI untuk migration) tambahkan ke `supabase/config.toml`:
   ```toml
   [auth.third_party.firebase]
   enabled = true
   project_id = "<firebase-project-id>"
   ```
6. <cite index="2-1">Nonaktifkan Email Auth Provider yang lama (magic link) di Authentication → Providers, karena tidak dipakai lagi</cite>

---

## 7. Perubahan di Sisi Flutter 🛠️

1. Tambahkan dependency ke `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^3.x
     firebase_auth: ^5.x
     google_sign_in: ^6.x
     supabase_flutter: ^2.x   # tetap dipakai untuk database, storage, realtime
   ```
2. Inisialisasi Firebase di `main.dart` **menggunakan `firebase_options.dart` hasil `flutterfire configure`** (bukan config manual), sebelum inisialisasi Supabase:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
3. Konfigurasi Supabase client dengan `accessToken` callback yang mengembalikan Firebase ID Token:
   ```dart
   final supabase = SupabaseClient(
     supabaseUrl,
     supabaseAnonKey,
     accessToken: () async {
       final user = FirebaseAuth.instance.currentUser;
       return user != null ? await user.getIdToken() : null;
     },
   );
   ```
4. Ganti seluruh isi `features/auth/` (yang sebelumnya berbasis `signInWithOtp`) dengan flow Google Sign-In (`google_sign_in` + `FirebaseAuth.signInWithCredential`)
5. `AuthController` (Riverpod, sesuai konvensi di `ARCHITECTURE.md` bagian 4) diperbarui untuk expose state Firebase user, bukan Supabase session

---

## 8. Draft Perubahan Database (Menunggu Approval Opsi A/B di Bagian 4)

Ditulis sebagai **draft migration tambahan** `009_migrate_auth_to_firebase.sql` — **belum dijalankan**, menunggu review.

```sql
-- ============================================================
-- 009: Migrate auth references from Supabase Auth to Firebase
-- DRAFT — DO NOT RUN before developer approval (see ISSUE.md §4)
-- Written assuming Opsi A (profiles.id becomes text = Firebase UID)
-- ============================================================

-- 1. Drop FK to auth.users (Konflik #3)
alter table public.profiles drop constraint profiles_id_fkey;

-- 2. Change profiles.id and every referencing FK from uuid -> text
--    (Konflik #1). Run only after confirming no existing production
--    data needs migrating — for a fresh project this is safe;
--    for an already-live project this needs a data migration plan.
alter table public.profiles alter column id type text;

alter table public.arisan_periods alter column host_id type text;
alter table public.arisan_periods alter column winner_id type text;
alter table public.payments alter column member_id type text;
alter table public.payments alter column recorded_by type text;
alter table public.donations alter column member_id type text;
alter table public.draws alter column winner_id type text;
alter table public.draws alter column conducted_by type text;
alter table public.draws alter column eligible_member_ids type text[]
  using eligible_member_ids::text[];
alter table public.event_photos alter column uploaded_by type text;
alter table public.app_settings alter column updated_by type text;
alter table public.fund_ledger alter column created_by type text;
alter table public.gathering_events alter column created_by type text;
alter table public.gathering_votes alter column member_id type text;
alter table public.invite_codes alter column created_by type text;
alter table public.invite_codes alter column revoked_by type text;

-- 3. Replace is_admin() to read the JWT sub claim as text
--    instead of relying on auth.uid() (Konflik #2)
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (auth.jwt() ->> 'sub') and role = 'admin'
  );
$$;

-- 4. Example RLS policy rewrite pattern — REPEAT for every policy
--    in 006_rls_policies.sql that currently uses auth.uid().
--    Before:
--      using (id = auth.uid() or public.is_admin())
--    After:
--      using (id = (auth.jwt() ->> 'sub') or public.is_admin())

-- 5. Storage policy rewrite pattern (008_storage_buckets.sql):
--    Before:
--      auth.uid()::text = (storage.foldername(name))[1]
--    After:
--      (auth.jwt() ->> 'sub') = (storage.foldername(name))[1]
```

**Catatan:** file draft ini sengaja **tidak** saya taruh sebagai migration resmi bernomor urut jalan otomatis — supaya tidak keklik/ke-run tanpa sadar sebelum kamu approve Opsi A vs B di bagian 4.

---

## 9. Checklist Fungsi yang Berpotensi Rusak — Perlu Diverifikasi Ulang Setelah Migrasi

| Fungsi/Fitur | File Terkait | Alasan Terdampak | Status |
|---|---|---|---|
| `is_admin()` | `004_functions_triggers.sql` | Pakai `auth.uid()` | 🔴 Perlu diubah |
| Semua RLS `SELECT`/`INSERT`/`UPDATE` policy | `006_rls_policies.sql` | Pakai `auth.uid()`, beberapa bandingkan ke kolom `uuid` yang akan jadi `text` | 🔴 Perlu diubah |
| Storage policy avatar & event-photos | `008_storage_buckets.sql` | Pakai `auth.uid()::text` | 🔴 Perlu diubah |
| Trigger `fn_allocate_payment_to_fund` | `004_functions_triggers.sql` | Tidak pakai `auth.uid()` langsung — **aman**, tapi kolom `created_by`/`recorded_by` yang direferensikan berubah tipe | 🟡 Perlu re-test |
| Trigger `fn_check_gathering_voting_complete` | `004_functions_triggers.sql` | Tidak pakai `auth.uid()` langsung — **aman**, hanya baca `profiles.is_active` | 🟢 Kemungkinan tidak berubah |
| RPC `get_gathering_vote_tally` | `005_gathering_vote_tally.sql` | `SECURITY DEFINER`, tidak bergantung `auth.uid()` — **aman** | 🟢 Tidak berubah |
| Edge Function `generate-invite-code`, `revoke-invite-code` | Kontrak di `ARCHITECTURE.md` 5.1 | Tidak bergantung auth flow user, dipanggil admin dengan `service_role` — **relatif aman**, hanya perlu pastikan `created_by`/`revoked_by` dikirim sebagai Firebase UID (text) | 🟡 Perlu re-test |
| Edge Function `redeem-invite-code` | Kontrak di `ARCHITECTURE.md` 5.1 | **Didesain ulang total** — lihat Konflik #4 | 🔴 Rombak total |
| Auto-generate row `profiles` setelah login | `ARCHITECTURE.md` 5.1 | Trigger sebelumnya "setelah verifikasi magic link" — sekarang "setelah Google Sign-In sukses" | 🔴 Perlu diubah |
| `AuthController` (Riverpod) | `features/auth/` | Berbasis Supabase session — perlu diubah expose Firebase user state | 🔴 Perlu diubah |
| Fitur lain (`draw`, `gathering`, `payments`, dst) yang tidak sentuh auth langsung | — | Tidak ada perubahan logic, hanya perlu pastikan tipe data `member_id`/`created_by` dsb konsisten `text` di seluruh pemanggilan | 🟡 Perlu re-test |

Legenda: 🔴 pasti perlu diubah · 🟡 perlu re-test tapi kemungkinan aman · 🟢 kemungkinan besar tidak terdampak

---

## 10. Yang TIDAK Berubah (Konfirmasi Scope)

- Struktur tabel inti (`arisan_periods`, `payments`, `donations`, `draws`, `event_checklist`, `event_photos`, `gathering_events`, `gathering_poll_options`, `gathering_votes`, `fund_ledger`, `notifications`) — hanya tipe kolom FK ke `profiles.id` yang berubah, bukan struktur/relasinya
- Supabase tetap dipakai penuh untuk: Postgres database, Storage (foto), Realtime (kocokan & voting), Edge Functions (kocokan, invite code generate/revoke)
- `DESIGN_SYSTEM.md` — tidak ada perubahan visual dari migrasi ini, hanya perlu tambah 1 tombol "Lanjut dengan Google" mengikuti tema warna yang sudah ada (Emerald Bani sebagai warna tombol, ikon Google standar di sebelah kiri teks)

---

## 11. Rencana Rollback

Karena project ini kemungkinan belum live/belum ada data produksi:
- Kalau migrasi gagal di tengah jalan, cukup restore dari backup Supabase sebelum migration `009` dijalankan (Supabase otomatis backup harian di plan berbayar; untuk free tier, export manual dulu sebelum migrasi lewat `pg_dump` atau Table Editor export)
- Simpan juga snapshot `config.toml` & kode Flutter sebelum migrasi di branch Git terpisah (`pre-firebase-auth`)

---

## 12. Checklist Implementasi

Centang `[x]` tiap task setelah selesai dikerjakan, supaya progres migrasi jelas dan tidak ada yang terlewat. Urutan di bawah ini juga disarankan jadi urutan pengerjaan.

### A. Approval & Keputusan (harus selesai duluan)
- [ ] Approve **Opsi A/B** untuk tipe data `profiles.id` & FK terkait (lihat §4 Konflik #1)
- [ ] Approve **Opsi A/B** untuk alur invite code (lihat §4 Konflik #4)
- [ ] Konfirmasi kesiapan pakai Firebase Blaze plan (biaya Cloud Functions)

### B. Firebase Console & CLI
- [ ] Buat project Firebase (`bani-rasijan`)
- [ ] Install `firebase-tools` & `flutterfire_cli`, `firebase login`
- [ ] Jalankan `flutterfire configure`, pilih platform Android + iOS
- [ ] Verifikasi `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` sudah muncul di project
- [ ] Aktifkan **Google** sebagai Sign-in Provider di Authentication
- [ ] Generate SHA-1 & SHA-256 (`./gradlew signingReport`), daftarkan ke Firebase Console
- [ ] Catat Firebase Project ID untuk step Supabase
- [ ] Buat & deploy Cloud Function `beforeUserCreated` (custom claim `role: authenticated`)
- [ ] Upgrade project ke Blaze plan

### C. Supabase Dashboard
- [ ] Tambahkan integrasi **Third-Party Auth → Firebase** dengan Project ID yang sudah dicatat
- [ ] (Kalau pakai CLI) update `supabase/config.toml` dengan block `[auth.third_party.firebase]`
- [ ] Nonaktifkan Email Auth Provider (magic link) yang lama

### D. Database Migration (Supabase)
- [ ] Finalisasi `009_migrate_auth_to_firebase.sql` sesuai Opsi A/B yang di-approve
- [ ] Drop FK `profiles.id → auth.users(id)`
- [ ] Ubah tipe kolom `uuid` → `text` di 11 kolom yang terdampak (lihat tabel §4 Konflik #1) — *lewati langkah ini kalau pilih Opsi B*
- [ ] Update `is_admin()` pakai `(auth.jwt() ->> 'sub')`
- [ ] Update seluruh RLS policy di `006_rls_policies.sql` yang pakai `auth.uid()`
- [ ] Update policy Storage di `008_storage_buckets.sql`
- [ ] Jalankan migration di environment **staging/dev dulu**, verifikasi tidak ada error
- [ ] Jalankan migration di production

### E. Edge Functions
- [ ] Desain ulang `redeem-invite-code` sesuai Opsi A/B alur invite code yang di-approve
- [ ] Update `generate-invite-code` & `revoke-invite-code` — pastikan `created_by`/`revoked_by` konsisten Firebase UID (text)
- [ ] Buat Edge Function baru untuk "selesaikan pendaftaran" (create row `profiles` setelah Google Sign-In + validasi invite code), kalau Opsi A dipilih di alur invite code
- [ ] Deploy & test semua Edge Function yang berubah

### F. Flutter App
- [ ] Tambahkan dependency `firebase_core`, `firebase_auth`, `google_sign_in`
- [ ] Inisialisasi Firebase di `main.dart` pakai `firebase_options.dart`
- [ ] Setup `accessToken` callback di Supabase client (kirim Firebase ID Token)
- [ ] Rombak `features/auth/` — ganti UI & logic dari magic link ke Google Sign-In
- [ ] Update `AuthController` (Riverpod) expose Firebase user state
- [ ] Tambah tombol "Lanjut dengan Google" mengikuti `DESIGN_SYSTEM.md` (warna Emerald Bani, ikon Google)
- [ ] Update flow lengkapi profil pertama kali (setelah Google Sign-In sukses, bukan setelah verifikasi OTP)

### G. Testing & Verifikasi Ulang (checklist dari §9)
- [ ] Login/logout dengan Google berhasil di Android
- [ ] Login/logout dengan Google berhasil di iOS
- [ ] `is_admin()` mengembalikan hasil benar untuk user admin & non-admin
- [ ] RLS `profiles` — user hanya bisa update profil sendiri, admin bisa update semua
- [ ] RLS `payments`, `donations`, `draws`, `fund_ledger` — read semua anggota, write admin-only tetap berfungsi
- [ ] RLS `gathering_votes` — toggle visibilitas voting tetap berfungsi
- [ ] RPC `get_gathering_vote_tally` tetap berjalan normal
- [ ] Storage: upload & lihat foto profil (avatars) berfungsi
- [ ] Storage: upload & lihat foto acara (event-photos) berfungsi
- [ ] Trigger alokasi kas gathering (`fn_allocate_payment_to_fund`) tetap jalan saat status payment diubah jadi `paid`
- [ ] Trigger auto-close voting (`fn_check_gathering_voting_complete`) tetap jalan saat semua anggota vote
- [ ] Alur invite code end-to-end (generate → redeem → profile ter-create) berjalan sesuai Opsi yang dipilih
- [ ] Realtime kocokan & voting tetap broadcast normal ke semua device

### H. Cleanup
- [ ] Hapus dependency lama yang tidak dipakai lagi (kalau ada package Supabase Auth OTP UI khusus)
- [ ] Hapus/arsipkan dokumentasi lama yang menyebut "magic link" di `PRD.md` & `ARCHITECTURE.md`, ganti dengan referensi Google Sign-In
- [ ] Update `ARCHITECTURE.md` bagian 5.1 secara permanen (bukan cuma di `ISSUE.md` ini) setelah migrasi selesai & stabil

---

## 13. Ringkasan Keputusan yang Perlu Kamu Approve

Sebelum saya lanjut menuliskan migration resmi & kode Edge Function:

1. ✅ / ❌ **Opsi A** (ubah `profiles.id` & FK terkait jadi `text`) — atau **Opsi B** (kolom `firebase_uid` terpisah)?
2. ✅ / ❌ **Opsi A** untuk alur invite code (gate kode di depan Google Sign-In) — atau **Opsi B** (Google Sign-In dulu, baru gate kode)?
3. Konfirmasi: project Firebase pakai Blaze plan (untuk Auth Blocking Function custom claim) — ada concern soal biaya?
