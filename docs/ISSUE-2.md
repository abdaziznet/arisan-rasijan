# ISSUE-2: Migrasi Authentication — Magic Link → Supabase Native Google Sign-In (OAuth 2.0)

**Status:** Completed — Code & Tests Implemented (Zero Issues)  
**Scope:** Authentication. Menggunakan **Supabase Native Auth** + **Google Sign-In** (`google_sign_in` ID Token). **TIDAK menggunakan Firebase Auth**.  
**Terkait:** `PRD.md`, `DATABASE_SCHEMA.md`, `ARCHITECTURE.md`, `DESIGN_SYSTEM.md`

---

## 1. Panduan Eksekusi & Standar Kualitas (Wajib Dipatuhi)

1. **Wajib Memanfaatkan Skills Project**:
   - Arsitektur & State Management: Manfaatkan skill `.agents/skills/flutter-apply-architecture-best-practices` atau `.claude/skills/flutter-apply-architecture-best-practices`.
   - Testing: Manfaatkan skill `.agents/skills/flutter-add-widget-test`.
   - UI & Layout: Manfaatkan skill `.agents/skills/flutter-build-responsive-layout` dan `.claude/skills/frontend-design`.
   - Supabase: Manfaatkan skill `.agents/skills/supabase` dan `.agents/skills/supabase-postgres-best-practices`.
2. **Prinsip Test-Driven Development (TDD)**:
   - Buat Unit Test dan Widget Test **sebelum** mengimplementasikan perubahan kode repository, controller, atau screen.
   - Pastikan test mencakup *success state*, *error state*, dan *user cancellation*.
3. **Standar Zero Error**:
   - Semua test wajib pass (`flutter test`).
   - Kode wajib lolos linter tanpa error atau warning (`flutter analyze`).
   - Setelah seluruh verifikasi lolos, checklist di bagian akhir dokumen ini wajib diupdate.

---

## 2. Ringkasan Perubahan

| Komponen | Sebelum | Sesudah (Revisi) |
| --- | --- | --- |
| **Metode Login** | Supabase Auth — Email Magic Link / OTP | **Supabase Auth — Google Sign-In Native** via `google_sign_in` + `signInWithIdToken` |
| **Auth Provider** | Supabase Internal (`email`) | Supabase Internal (`google` OAuth provider) |
| **User Store** | `auth.users` Supabase | **Tetap `auth.users` Supabase** |
| **Tipe Data `profiles.id`** | `uuid` (referensi `auth.users.id`) | **Tetap `uuid` (0 breaking change)** |
| **RLS & Functions** | `auth.uid()` bawaan Postgres | **Tetap `auth.uid()` bawaan (tidak ada yang diubah)** |
| **Backend / DB** | Supabase Postgres, RLS, Storage | **100% Supabase (tanpa Firebase, tanpa Blaze plan)** |

---

## 3. Keuntungan Arsitektur Native (vs Firebase Auth)

1. **Zero Database Breaking Changes**:
   - Tipe data `uuid` di 11 tabel tetap aman (`profiles`, `payments`, `draws`, `arisan_periods`, dll).
   - FK `profiles.id -> auth.users(id)` tetap valid dan menjaga integritas data.
   - Semua RLS policy (`006_rls_policies.sql`), SQL functions (`is_admin()`), dan Storage policy (`008_storage_buckets.sql`) tidak perlu diubah.
2. **100% Gratis & Bebas Maintenance Cloud Functions**:
   - Tidak butuh Firebase Blaze plan (kartu kredit) atau Firebase Auth Blocking Function untuk custom claims.
3. **Session & Realtime Terintegrasi Penuh**:
   - Token refresh ditangani otomatis oleh `supabase_flutter`.
   - Realtime channel, Storage, dan RPC langsung menerima user session yang valid.

---

## 4. Alur Kerja Autentikasi (Native Google Sign-In Flow)

```text
[User tap "Lanjut dengan Google"]
              │
              ▼
[Flutter: google_sign_in.signIn()]
              │
              ▼
[Dapatkan Google idToken & accessToken]
              │
              ▼
[supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: ..., accessToken: ...)]
              │
              ▼
[Supabase memvalidasi token Google & mencatat user di auth.users]
              │
              ▼
[Cek apakah row profiles sudah ada?]
     ├── YA  ──> [Langsung masuk Home Dashboard]
     └── TIDAK ──> [Arahkan ke Screen "Masukkan Kode Undangan & Lengkapi Profil"]
                        │
                        ▼
            [Validasi invite code & create profile]
                        │
                        ▼
            [Masuk Home Dashboard]
```

---

## 5. Alur Invite Code & Pembuatan Profile

Karena Google Sign-In langsung membuat user di `auth.users`, gating anggota keluarga dilakukan pada tahap **pembuatan profil**:

1. User baru berhasil login Google pertama kali -> terdaftar di `auth.users`, tapi **belum punya row di `public.profiles`**.
2. Router aplikasi mendeteksi user login tanpa data `profiles` -> redirect ke **`InviteCodeScreen` / `ProfileCompletionScreen`**.
3. User menginput kode undangan & nama lengkap/panggilan keluarga.
4. Sistem memvalidasi kode undangan via Edge Function `redeem-invite-code` atau RPC:
   - Jika valid: buat row di `public.profiles` (`id = auth.uid()`, `is_active = true`), inkremen `used_count` di `invite_codes`.
   - Jika tidak valid: beri pesan error, user tidak bisa mengakses fitur arisan sampai memasukkan kode yang benar.

---

## 6. Setup & Konfigurasi Eksternal

### A. Google Cloud Console (OAuth 2.0 Credentials)

1. **Web Client ID (Server Client)**:
   - Digunakan untuk konfigurasi di Supabase Dashboard dan `serverClientId` di Flutter.
   - Authorized redirect URIs: Masukkan Supabase Callback URL (`https://iggwgsuvdtcowlypnglj.supabase.co/auth/v1/callback`).
2. **Android Client ID**:
   - Package name: `com.example.bani_rasijan` (sesuai `android/app/build.gradle.kts`).
   - SHA-1 Certificate Fingerprint: didapat dari `./gradlew signingReport` (Debug & Release keystore).
3. **iOS Client ID (jika target iOS)**:
   - Bundle ID: `com.example.baniRasijan`.

### B. Supabase Dashboard

1. Buka **Authentication -> Providers -> Google**.
2. Toggle **Enable Google provider**.
3. Masukkan **Client ID** (Web Client ID dari Google Cloud Console).
4. Masukkan **Client Secret** (dari Web Client ID Google Cloud Console).
5. Simpan pengaturan.

---

## 7. Perubahan Sisi Flutter App

### A. Dependency (`pubspec.yaml`)

Tambahkan package `google_sign_in`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.17.1
  google_sign_in: ^6.2.2
  flutter_riverpod: ^2.6.1
  # ... dependency lainnya tetap
```

### B. Environment Config (`.env` & `lib/core/config/env_config.dart`)

Tambahkan Web Client ID untuk parameter `serverClientId` Google Sign-In di Android:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
```

### C. Implementasi Auth Repository (`lib/features/auth/data/auth_repository.dart`)

```dart
class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._supabase, {String? webClientId})
      : _googleSignIn = GoogleSignIn(serverClientId: webClientId);

  Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In dibatalkan oleh user');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('ID Token Google tidak ditemukan');
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
```

### D. UI Login (`lib/features/auth/presentation/screens/login_screen.dart`)

- Ganti input form email magic link dengan tombol **"Lanjut dengan Google"** (mengikuti styling `DESIGN_SYSTEM.md`, warna Emerald Bani dengan ikon Google).

---

## 8. Checklist Implementasi

### A. Konfigurasi

- [x] Daftarkan SHA-1 fingerprint ke Google Cloud Console (Android Client ID).
- [x] Aktifkan Google Provider di Supabase Dashboard (isi Web Client ID, Secret, dan pastikan Callback URL cocok).
- [x] Tambahkan `GOOGLE_WEB_CLIENT_ID` ke `.env` dan `EnvConfig`.

### B. Flutter Codebase & Tests (TDD)

- [x] Tambahkan `google_sign_in: ^6.2.2` ke `pubspec.yaml`.
- [x] Buat Unit Test untuk `AuthRepository` (`test/features/auth/data/auth_repository_test.dart`).
- [x] Buat Unit Test untuk `AuthController` (`test/features/auth/presentation/controllers/auth_controller_test.dart`).
- [x] Buat Widget Test untuk `LoginScreen` (`test/features/auth/presentation/screens/login_screen_test.dart`).
- [x] Implementasikan `AuthRepository` untuk Google Sign-In (`signInWithIdToken`).
- [x] Implementasikan `AuthController` & State untuk menangani flow login Google.
- [x] Implementasikan `LoginScreen` dengan tombol Google Sign-In.
- [x] Sesuaikan router & flow `ProfileCompletionScreen` / `InviteCodeScreen` untuk user Google baru.

### C. Testing & Verifikasi

- [x] Jalankan seluruh suite test (`flutter test`) - 100% Passed.
- [x] Jalankan analisis statis (`flutter analyze`) - 0 errors, 0 warnings.
- [x] Uji login Google di perangkat Android langsung (membutuhkan device fisik / emulator dengan akun Google terpasang).
- [ ] Pastikan seluruh RLS data (`payments`, `draws`, `gathering`) tetap berfungsi normal.
