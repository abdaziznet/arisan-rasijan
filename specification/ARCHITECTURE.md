# Architecture Document
## Aplikasi Arisan Keluarga

**Versi:** 1.0
**Terkait:** `PRD.md`, `DATABASE_SCHEMA.md`

---

## 1. Ringkasan Stack

| Layer | Teknologi | Alasan |
|---|---|---|
| Mobile App | **Flutter** | Cross-platform Android & iOS dalam satu codebase |
| State Management | **Riverpod** | Controller dikelompokkan per fitur, konsisten dengan struktur feature-first |
| Backend & Database | **Supabase** (PostgreSQL) | Backend-as-a-service lengkap: Auth, DB, Storage, Realtime, Edge Functions |
| Auth | **Supabase Auth — Email Magic Link/OTP** | Tanpa password, tanpa biaya SMS |
| Storage Foto | **Supabase Storage** | Terintegrasi langsung dengan Auth & RLS |
| Realtime | **Supabase Realtime** | Update hasil kocokan secara live ke semua device |
| Business Logic Sensitif | **Supabase Edge Functions** | Untuk proses kocokan agar tidak bisa dimanipulasi dari client |
| Distribusi | **Google Play Console — Internal/Closed Testing** | App privat, tidak perlu rilis publik |

---

## 2. Arsitektur Sistem (High Level)

```
┌─────────────────────────┐
│      Flutter App        │
│  (Android / iOS client) │
└───────────┬──────────────┘
            │ HTTPS (supabase_flutter SDK)
            ▼
┌─────────────────────────────────────────┐
│              Supabase Project             │
│                                           │
│  ┌───────────┐  ┌────────────┐  ┌──────┐ │
│  │   Auth    │  │  Postgres  │  │Storage│ │
│  │(Email OTP)│  │  Database  │  │(Photos)│ │
│  └───────────┘  └────────────┘  └──────┘ │
│                                           │
│  ┌───────────────┐   ┌─────────────────┐ │
│  │ Edge Functions │   │    Realtime     │ │
│  │ (proses kocokan)│  │ (broadcast hasil│ │
│  │                │   │  kocokan live)  │ │
│  └───────────────┘   └─────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 3. Struktur Folder Flutter (Disarankan)

Menggunakan pendekatan **feature-first** agar tiap modul (member, periode, kocokan, dll) mandiri dan mudah di-maintain:

```
lib/
├── main.dart
├── app.dart                      # MaterialApp, routing
├── core/
│   ├── config/                   # Supabase client init, env config
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/                  # shared/reusable widgets
├── features/
│   ├── auth/
│   │   ├── data/                 # repository, supabase calls
│   │   ├── domain/                # models
│   │   └── presentation/         # screens, providers/controllers
│   ├── members/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── periods/                  # jadwal & periode arisan
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── payments/                 # iuran & donasi
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── draw/                     # fitur kocokan (core feature)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── event_checklist/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── gallery/                  # dokumentasi foto
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── gathering/                # kas bersama, event gathering & voting
│       ├── data/
│       ├── domain/
│       └── presentation/
└── routing/
    └── app_router.dart
```

---

## 4. State Management

**Riverpod** dipilih sebagai state management utama, dengan controller dikelompokkan per fitur (bukan 1 controller besar global). Pola ini konsisten dengan struktur folder feature-first di atas — tiap `features/<nama_fitur>/presentation/` punya provider/controller-nya sendiri.

**Konvensi penamaan & lokasi:**

```
features/<nama_fitur>/presentation/
├── controllers/
│   └── <nama_fitur>_controller.dart   # StateNotifier/AsyncNotifier untuk fitur ini
├── providers/
│   └── <nama_fitur>_providers.dart    # Provider definitions (repository, controller)
└── screens/
    └── <nama_fitur>_screen.dart       # ConsumerWidget yang consume provider di atas
```

**Contoh per fitur:**

| Fitur | Controller | Tanggung Jawab |
|---|---|---|
| `auth` | `AuthController` (`AsyncNotifier`) | Status login, magic link, redeem invite code |
| `members` | `MembersController` | List anggota, CRUD profil |
| `periods` | `PeriodsController` | Periode berjalan, jadwal, tuan rumah |
| `payments` | `PaymentsController` | Status iuran & donasi per periode |
| `draw` | `DrawController` | Trigger kocokan, subscribe hasil Realtime |
| `event_checklist` | `EventChecklistController` | Checklist rundown acara |
| `gallery` | `GalleryController` | Upload & list foto |
| `gathering` | `GatheringController` | Kas gathering, voting, tally |

**Prinsip:**
- Data async dari Supabase (list anggota, periode, histori, dsb) dibungkus `AsyncNotifier`/`FutureProvider` dengan state loading–data–error yang jelas dan konsisten di semua fitur
- Realtime update (hasil kocokan, tally voting) di-subscribe di dalam controller terkait (`DrawController`, `GatheringController`), lalu di-expose sebagai `Stream`-based provider agar UI otomatis rebuild tanpa refresh manual
- Controller tidak saling mengakses controller fitur lain secara langsung — kalau butuh data lintas fitur (misal `gathering` butuh data `members` untuk cek anggota aktif), akses lewat provider/repository fitur tsb, bukan import controller-nya langsung — menjaga agar tiap fitur tetap independen dan mudah diuji terpisah

---

## 5. Modul Teknis per Fitur

### 5.1 Auth (Email Magic Link/OTP)
- Gunakan `supabase_flutter` SDK → `signInWithOtp(email: ...)`
- Deep link handling untuk menangkap redirect dari email (perlu setup `android/app/src/main/AndroidManifest.xml` dan `ios/Runner/Info.plist` untuk custom URL scheme)
- Setelah verifikasi, cek apakah `profiles` sudah ada untuk user tsb → jika belum, arahkan ke flow lengkapi profil (nama, no HP, foto)

**Kontrak Edge Function — Invite Code:**

Karena tabel `invite_codes` tidak boleh diakses langsung oleh client (lihat RLS di `DATABASE_SCHEMA.md` 2.14), pendaftaran anggota baru wajib lewat 2 Edge Function berikut (berjalan dengan `service_role` key):

**`generate-invite-code`** *(dipanggil admin)*
```
Request:  { expires_in_days: number, max_uses?: number }
Proses:   1. Generate kode acak (misal 8 karakter alfanumerik)
          2. Hash kode dengan bcrypt/SHA-256
          3. Insert ke invite_codes (code_hash, expires_at, max_uses, created_by)
Response: { code: string }   // kode plaintext HANYA dikembalikan sekali ini,
                              // tidak pernah disimpan/ditampilkan lagi setelahnya
```

**`redeem-invite-code`** *(dipanggil calon anggota baru, sebelum punya session)*
```
Request:  { code: string, email: string }
Proses:   1. Hash kode yang dikirim, cari baris invite_codes yang cocok
          2. Validasi: is_revoked = false, expires_at > now(), used_count < max_uses
          3. Jika valid: increment used_count, lalu trigger signInWithOtp
             untuk email tsb agar anggota lanjut ke flow magic link seperti biasa
          4. Jika tidak valid: kembalikan error tanpa detail spesifik
             (hindari membocorkan apakah kode salah/kadaluarsa/sudah revoked —
             cukup "Kode undangan tidak valid")
Response: { success: boolean, message: string }
```

**`revoke-invite-code`** *(dipanggil admin)*
```
Request:  { invite_code_id: uuid }
Proses:   Set is_revoked = true, revoked_by, revoked_at
Response: { success: boolean }
```

### 5.2 Fitur Kocokan
- Tombol "Mulai Kocokan" hanya muncul untuk role admin
- Saat ditekan → panggil Edge Function yang:
  1. Ambil daftar anggota eligible (exclude yang sudah pernah menang, jika opsi ini aktif)
  2. Random pilih 1 pemenang
  3. Simpan ke tabel `draws`
  4. Update `arisan_periods.winner_id` dan buat baris baru di `arisan_periods` untuk periode berikutnya dengan `host_id` = pemenang
- Hasil di-broadcast lewat Supabase Realtime → semua device yang membuka layar kocokan otomatis menampilkan animasi & hasil yang sama secara bersamaan

### 5.3 Notifikasi Reminder
- Bisa memakai **Supabase Edge Function + Cron (pg_cron)** yang berjalan terjadwal, dikombinasikan dengan **Firebase Cloud Messaging (FCM)** untuk push notification ke device (Supabase sendiri tidak native push notification, jadi FCM tetap dibutuhkan sebagai delivery channel)

### 5.4 Galeri Foto
- Upload langsung ke Supabase Storage bucket `event-photos`
- Kompres gambar di sisi client (Flutter) sebelum upload untuk menghemat storage & bandwidth

### 5.5 Kas Bersama & Event Gathering

**Alokasi otomatis ke kas gathering:**
- Saat admin mengubah status `payments` menjadi `'paid'`, jalankan **database trigger** yang:
  1. Ambil persentase potongan dari `app_settings` (`gathering_fund_percentage`)
  2. Hitung nominal alokasi, simpan ke `payments.allocated_to_fund`
  3. Insert baris baru ke `fund_ledger` dengan `type = 'contribution_allocation'`
- Total kas gathering ditampilkan di halaman utama dengan query `SUM(amount)` dari `fund_ledger` (bisa di-cache di state provider dan di-refresh via Realtime subscription agar semua anggota lihat angka yang sama tanpa perlu refresh manual)

**Voting tujuan gathering:**
- Admin membuat `gathering_events` baru (status awal `'voting'`) beserta beberapa `gathering_poll_options`
- Tiap anggota submit 1 baris ke `gathering_votes` (di-enforce unik lewat `UNIQUE(gathering_event_id, member_id)` di database)
- Setelah tiap vote masuk, **trigger/Edge Function** mengecek apakah jumlah vote sudah sama dengan jumlah anggota aktif → jika ya, otomatis:
  - Hitung opsi dengan suara terbanyak
  - Update `gathering_events.status` jadi `'decided'` dan set `winning_option_id`
- Hasil voting di-broadcast lewat **Supabase Realtime** ke layar semua anggota, mirip pola yang dipakai di fitur kocokan
- Setelah opsi terpilih, admin input `event_date` dan `fund_used` → sistem otomatis insert baris `'gathering_expense'` (nominal negatif) ke `fund_ledger`, mengurangi saldo kas gathering
- **Toggle visibilitas voting**: admin mengatur `app_settings.gathering_votes_visible_to_members` dari halaman pengaturan admin. Flutter client membaca nilai ini untuk menentukan tampilan:
  - Jika `'true'`: layar voting menampilkan daftar nama anggota beserta pilihannya (query langsung ke `gathering_votes`)
  - Jika `'false'`: layar voting hanya menampilkan tally angka per opsi (panggil RPC function `get_gathering_vote_tally`), tanpa menampilkan siapa memilih apa
  - Setting ini murni memengaruhi **apa yang ditampilkan/bisa diakses selama proses berlangsung** — hasil akhir (opsi pemenang) tetap terlihat semua anggota setelah voting resmi ditutup, karena itu bagian dari `gathering_events.winning_option_id` yang publik

---

## 6. Keamanan

- **Row Level Security (RLS)** aktif di semua tabel (detail lihat `DATABASE_SCHEMA.md`)
- Proses kocokan dijalankan di **Edge Function** (server-side), bukan di client, agar tidak bisa direkayasa
- Proses penutupan voting gathering & penghitungan opsi pemenang juga dijalankan server-side (trigger/Edge Function), bukan di client, untuk menghindari manipulasi hasil dan race condition saat beberapa anggota vote bersamaan
- Invite code untuk pendaftaran anggota baru disimpan terenkripsi/hash, punya masa berlaku, dan bisa di-revoke oleh admin — lihat model data di `DATABASE_SCHEMA.md` (2.14 `invite_codes`) dan kontrak Edge Function di bagian 5.1 di atas

---

## 7. Rencana Rilis ke Play Store

1. **Build & Signing**: siapkan keystore, konfigurasi `build.gradle` untuk release build
2. **Privacy Policy**: wajib dibuat (bisa halaman sederhana, karena app menyimpan data pribadi & keuangan anggota)
3. **Distribusi**: gunakan **Internal Testing** atau **Closed Testing** track di Play Console — cukup untuk skala keluarga, review lebih cepat dibanding rilis production publik
4. **App Signing**: aktifkan Play App Signing bawaan Google untuk keamanan tambahan

---

## 8. Roadmap Implementasi (Saran Urutan Development)

1. Setup project Supabase + Flutter, konfigurasi Auth Email OTP
2. Modul `profiles` & manajemen anggota
3. Modul `arisan_periods` (jadwal, tuan rumah)
4. Modul `payments` & `donations`
5. Modul `event_checklist`
6. Modul `draw` (fitur kocokan) — termasuk Edge Function & Realtime
7. Modul `event_photos` (galeri)
8. Modul `gathering` (kas bersama, voting) — termasuk trigger alokasi dana & Edge Function penutupan voting
9. Notifikasi reminder (FCM + Edge Function cron)
10. Testing menyeluruh + rilis Internal Testing di Play Console