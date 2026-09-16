# Bani Rasijan 🌺

Private mobile application for family arisan, contribution tracking, family gathering events, and shared archives for the **Bani Rasijan** family.

---

## 📌 Ringkasan Proyek

**Bani Rasijan** adalah aplikasi Android & iOS berbasis **Flutter** dan **Supabase** yang dirancang khusus untuk mengelola kegiatan arisan rutin keluarga besar Bani Rasijan (dilaksanakan 2 bulan sekali).
Aplikasi ini menggantikan pencatatan manual menjadi sistem digital yang transparan, aman, dan mudah diakses oleh seluruh anggota keluarga.

---

## ✨ Fitur Utama

- 🎲 **Kocokan Digital Transparan (Digital Draw)**
  - System undian acak terpusat yang adil dan transparan.
  - Animasi kocokan interaktif dengan pengumuman pemenang real-time.
  - Pemenang otomatis ditandai sebagai calon tuan rumah periode berikutnya.
  - Riwayat kocokan lengkap (pemenang, tanggal, dan lokasi).

- 💰 **Manajemen Iuran & Donasi**
  - Pencatatan status iuran wajib dan donasi sukarela per periode.
  - Upload & konfirmasi bukti pembayaran.
  - Verifikasi dan persetujuan status pembayaran oleh Admin / Bendahara.
  - Ringkasan total kas dan laporan saldo transparan.

- 📅 **Manajemen Periode & Acara**
  - Tracking jadwal arisan 2 bulanan.
  - Integrasi peta lokasi (`flutter_map`) menuju rumah tuan rumah atau lokasi gathering.
  - *Checklist* susunan acara (Pembacaan Yasin & Sholawat, Makan Bersama, Kocokan, Foto Bersama).

- 🗳️ **Acara Kumpul & Polling Gathering**
  - Polling penentuan tanggal dan lokasi kumpul keluarga.
  - Buku kas acara (*Fund Ledger*) untuk mencatat transparansi pengeluaran/pemasukan kegiatan.

- 👥 **Manajemen Anggota & Akses Privat**
  - Aplikasi privat berbasis Invite Code & Magic Link Auth (tanpa password).
  - Manajemen role pengguna (Admin/Bendahara & Anggota).
  - Pembuatan kode undangan baru oleh Admin.

- 🖼️ **Galeri Foto & Dokumentasi Keluarga**
  - Arsip dokumentasi foto bersama tiap periode arisan dan gathering.

---

## 🛠️ Stack Teknologi & Arsitektur

### Tech Stack

| Layer | Teknologi | Deskripsi / Fungsi |
| --- | --- | --- |
| **Mobile App** | [Flutter](https://flutter.dev) (Dart SDK `>=3.4.0 <4.0.0`) | Framework cross-platform Android & iOS |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) | Dependency injection & reactive state control |
| **Backend & DB** | [Supabase](https://supabase.com) (PostgreSQL) | Auth, Database, Storage, & Realtime broadcast |
| **Auth** | Supabase Auth | Email Magic Link / OTP & Google Sign-In |
| **Peta & Lokasi** | `flutter_map`, `latlong2`, `geolocator` | Visualisasi lokasi rumah tuan rumah & geolocator |
| **Code Generation** | `freezed`, `json_serializable`, `build_runner` | Immutable state models & JSON parsing |
| **Storage** | Supabase Storage | Penyimpanan bukti transfer & foto galeri keluarga |

### Arsitektur (Feature-First)

Struktur kode mengikuti pola **Feature-First Architecture** untuk keterbacaan dan pemeliharaan modul yang mandiri:

```text
lib/
├── main.dart                       # Entry point (Env & Supabase Init)
├── app.dart                        # MaterialApp, router & theme configuration
├── core/                           # Foundation, shared components & utilities
│   ├── config/                     # Supabase & Env configurations
│   ├── services/                   # Cache & Connectivity services
│   ├── theme/                      # App spacing, colors, radii, motion & theme
│   ├── utils/                      # Formatters & Validators
│   └── widgets/                    # Reusable UI components
└── features/                       # Application feature modules
    ├── auth/                       # Magic Link & Invite code handling
    ├── draw/                       # Digital draw (kocokan) & animation screens
    ├── events/                     # Event checklists & event steps
    ├── gallery/                    # Family photo album & storage
    ├── gathering/                  # Event polls, location voting & fund ledger
    ├── history/                    # Past arisan periods & winner logs
    ├── members/                    # Member directory & invite codes
    ├── payments/                   # Contribution & donation tracking
    ├── periods/                    # Period lifecycle management
    ├── profile/                    # User profile & location settings
    ├── settings/                   # Admin panel & app settings
    └── splash/                     # Initial splash screen
```

---

## 🚀 Panduan Memulai (Getting Started)

### Prasyarat

Sebelum menjalankan aplikasi, pastikan environment berikut sudah terpasang:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.4.0`)
- [Dart SDK](https://dart.dev/get-started)
- [Git](https://git-scm.com/)

### Langkah Instalasi

1. **Clone repository ini:**

   ```bash
   git clone https://github.com/<owner>/arisan_rasijan.git
   cd arisan_rasijan
   ```

2. **Install dependensi Flutter:**

   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment (`.env`):**
   Salin `.env.example` menjadi `.env` di root project:

   ```bash
   cp .env.example .env
   ```

   Isi variabel kredensial Supabase Anda di file `.env`:

   ```env
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GOOGLE_WEB_CLIENT_ID=your-optional-google-client-id
   ```

4. **Jalankan Code Generation (jika merubah data models):**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Jalankan Aplikasi:**

   ```bash
   # Android / iOS / Web
   flutter run
   ```

---

## 🧪 Testing & Analisis Kode

Jalankan perintah berikut untuk memastikan kualitas kode dan linting:

```bash
# Analisis static code
flutter analyze

# Jalankan unit & widget test
flutter test
```

---

## 📄 Dokumentasi Tambahan

Detail spesifikasi teknis dan desain aplikasi dapat ditemukan pada folder dokumentasi berikut:

- [`specification/PRD.md`](specification/PRD.md) — Product Requirements Document (kebutuhan produk & alur bisnis)
- [`specification/ARCHITECTURE.md`](specification/ARCHITECTURE.md) — Spesifikasi arsitektur sistem & infrastruktur
- [`specification/DATABASE_SCHEMA.md`](specification/DATABASE_SCHEMA.md) — Skema database PostgreSQL & Supabase RLS policies
- [`design/`](design/) — Panduan UI/UX & asset visual

---

## 🔐 Keamanan & Lisensi

- Aplikasi ini bersifat **Privat** (`publish_to: none`).
- Hanya anggota yang terdaftar dengan *Invite Code* valid yang dapat mengakses data keluarga.
- Hak Cipta © 2026 Keluarga Besar **Bani Rasijan**. All Rights Reserved.
