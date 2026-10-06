# ISSUE-5: Implementasi Biometric Authentication (Kunci Layar Lokal & App Lock)

**Status:** Implementation Complete — Verification Ready  
**Prioritas:** Medium — Security & UX Enhancement  
**Scope:** Auth, Splash, App Lifecycle, Settings, Biometric Service, Storage Preferences, Testing, and Platform Configuration  
**Terkait:** `PRD.md`, `ARCHITECTURE.md`, `DESIGN.md`, `lib/core/theme/`, `lib/features/auth/`, `lib/features/settings/`

---

## 1. Tujuan

Menambahkan fitur autentikasi biometrik (sidik jari / Face ID) sebagai **kunci layar lokal (local app lock)** pada aplikasi BANI RASIJAN. Fitur ini meningkatkan kenyamanan dan privasi anggota keluarga tanpa mengubah arsitektur keamanan backend yang sudah berjalan.

Autentikasi biometrik berfungsi sebagai lapisan proteksi lokal di perangkat. Fitur ini **bukan bukti identitas ke server**. Keamanan data dan otorisasi akses database tetap sepenuhnya bergantung pada Supabase JWT, Session expiry, dan PostgreSQL Row Level Security (RLS).

### Hasil akhir yang diharapkan

1. Deteksi otomatis kemampuan biometrik perangkat (hardware support, enrolled biometrics). Jika tidak didukung, UI biometrik disembunyikan secara bersih tanpa error.
2. Penawaran aktivasi opsional (Bottom Sheet) setelah user berhasil login Google pertama kali atau saat login ulang.
3. Kunci aplikasi saat dibuka dari *cold start* jika session Supabase masih aktif dan biometrik diaktifkan.
4. Kunci aplikasi otomatis saat kembali dari background jika durasi meninggalkan app melebihi ambang batas $N$ menit ($1$–$5$ menit, dapat diatur).
5. Fallback login ulang via Google Sign-In jika biometrik gagal, dibatalkan, atau sensor mengalami malfungsi.
6. Proteksi batas percobaan gagal (default: 3 kali berturut-turut), setelah itu sesi lokal dikunci dan user dipaksa login ulang via Google.
7. Menu pengaturan pada profil/pengaturan untuk mengaktifkan/menonaktifkan fitur dan memilih durasi timeout auto-lock.
8. Deteksi perubahan biometrik perangkat (misal penambahan sidik jari baru di OS) yang memicu invalidasi kunci dan meminta login ulang demi keamanan.
9. Tampilan modern dengan animasi halus sesuai `AppMotion` dan palet warna Emerald/Gold konsisten sesuai `DESIGN.md`.
10. Seluruh test existing tetap lolos tanpa regresi, didukung unit test dan widget test baru untuk setiap komponen biometrik.

---

## 2. Panduan Eksekusi dan Standar Kualitas

### 2.1 Skills yang wajib digunakan

- `flutter-apply-architecture-best-practices`: Pembagian clean layer (data source, repository/service, domain state, presentation controller & widgets) mengikuti pola feature-first.
- `flutter-animations`: Transisi layar lock, icon shake pada kegagalan auth, pulse effect pada sensor prompt, dan smooth dismiss bottom sheet.
- `frontend-design`: Konsistensi desain BANI RASIJAN (Modern Family Minimalism, 60-30-10 color rule, touch target 48px, typografi Plus Jakarta Sans).
- `flutter-build-responsive-layout`: Memastikan dialog, lock screen, dan bottom sheet responsif di berbagai ukuran layar dan font scaling besar.
- `flutter-add-widget-test`: Pengujian komponen UI, interaction states, dialog flow, fallback triggers, dan lifecycle transitions.
- `dart-flutter:dart-add-unit-test`: Pengujian logic controller, state transitions, debounce/timer background, dan error handling adapter.

### 2.2 Aturan implementasi

- Gunakan feature-first structure: `lib/features/biometric/` sebagai modul mandiri.
- Jangan mengakses package `local_auth` langsung dari presentation layer; bungkus dalam `BiometricService` di data layer agar mudah di-mock dalam testing.
- Jangan menyimpan data biometrik (template sidik jari / citra wajah) di aplikasi — OS mengelola hardware security module (Secure Enclave / Android Keystore / BiometricPrompt).
- Jangan menyimpan password atau credential mentah di SharedPreferences. Hanya simpan flag preferensi (`is_biometric_enabled: bool`, `lock_timeout_minutes: int`, `last_background_timestamp: int`, `biometric_enrolled_hash: String?`).
- Jangan pernah bypass Supabase Auth. Jika session Supabase null / expired, biometrik tidak boleh membuka app langsung ke Home; user wajib diarahkan ke Login Google.
- Semua async state wajib menangani state: `initial`, `loading`, `success`, `failure`, `lockedOut`, dan `notAvailable`.
- Gunakan `AppMotion` (`quick: 180ms`, `standard: 300ms`) untuk seluruh animasi UI.
- Kompatibel penuh untuk Android (API level 23+ / BiometricPrompt API) dan iOS (iOS 12+ / LocalAuthentication Face ID & Touch ID).

### 2.3 TDD dan standar verifikasi

- Tulis unit test untuk `BiometricService`, `BiometricPreferences`, dan `BiometricController` sebelum menghubungkan ke UI.
- Tulis widget test untuk `BiometricLockScreen`, `BiometricActivationSheet`, dan integrasi tombol biometrik pada `LoginScreen`.
- Verifikasi cold start flow dan lifecycle transition via integration/unit test dengan mocking `WidgetsBindingObserver`.
- Jalankan `flutter test` untuk memastikan semua test suite (existing + new) pass 100%.
- Jalankan `flutter analyze` dan pastikan zero warning / zero error.

---

## 3. Scope dan Batasan

### 3.1 In scope

- Integrasi package `local_auth` modern compatible dengan Flutter SDK `>=3.4.0 <4.0.0`.
- Service adapter `BiometricService` untuk abstraksi hardware capability, authentication prompt, dan biometrics type check (Face ID vs Fingerprint).
- Penyimpanan preferensi lokal (`BiometricPreferences`) menggunakan `SharedPreferences`.
- Layar kunci biometrik (`BiometricLockScreen`) dengan visual modern, animasi feedback, indikator percobaan, dan tombol fallback Google Auth.
- Prompt / Bottom Sheet aktivasi biometrik pasca login Google berhasil (`BiometricActivationSheet`).
- Shortcut tombol biometrik pada `LoginScreen` jika user sudah pernah login dan mengaktifkan fitur biometrik sebelumnya.
- Lifecycle observer di root widget (`BaniRasijanApp` / `AppLifecycleManager`) untuk mendeteksi durasi background dan memicu lock screen saat timeout terlampaui.
- Pilihan konfigurasi durasi timeout auto-lock ($1$ menit, $2$ menit, $3$ menit, $5$ menit, atau $0$ menit / langsung kunci) di menu Pengaturan.
- Toggle aktif/nonaktif biometrik pada menu Pengaturan (Profile / Settings).
- Limit percobaan gagal maksimal 3x dengan feedback visual (shake animation, counter sisa percobaan) dan auto-logout paksa jika melampaui limit.
- Deteksi perubahan hardware biometric enrollment (invalidasi token lokal dan re-login prompt).
- Konfigurasi Android (`AndroidManifest.xml`, `MainActivity.kt` jika perlu `FlutterFragmentActivity`) dan iOS (`Info.plist` `NSFaceIDUsageDescription`).
- Unit tests, widget tests, dan automated test coverage.

### 3.2 Out of scope

- Penggantian Supabase Auth dengan biometrik (biometrik bukan custom auth provider di backend).
- Penyimpanan private key cryptographic hardware signature ke server database.
- Web/Desktop biometric support (aplikasi target: mobile Android & iOS).
- Custom biometric scanner UI (kamera custom untuk Face recognition) — wajib menggunakan system dialog native OS demi keamanan dan privasi.
- PIN/Passcode manual sekunder kustom di dalam aplikasi (fallback langsung ke Google Sign-In existing).

---

## 4. Keamanan & Arsitektur Data

### 4.1 Prinsip Keamanan Kunci Layar (Screen Lock)

```text
+-------------------------------------------------------------------------+
|                              PERANGKAT                                  |
|                                                                         |
|  [ Cold Start / Resume ]                                                |
|            │                                                            |
|            ▼                                                            |
|  +──────────────────+      Valid      +──────────────────────────────+  |
|  |  Biometric Lock  | ──────────────> |   Home Screen / Fitur App    |  |
|  |  (local_auth OS) |                 +──────────────────────────────+  |
|  +──────────────────+                                │                  |
|            │ Gagal 3x / Batal                        │ Supabase JWT     |
|            ▼                                         ▼ (RLS Protected)  |
|  +──────────────────+                  +─────────────────────────────+  |
|  |   Google Auth    |                  |      Supabase Backend       |  |
|  |  (Supabase Login)| ───────────────> |      (PostgreSQL + RLS)     |  |
|  +──────────────────+                  +─────────────────────────────+  |
+-------------------------------------------------------------------------+
```

1. **Client-Side Gate Only**: Biometrik hanya mengizinkan navigasi ke tampilan aplikasi yang terlindungi di sisi klien.
2. **Server Trust Model**: Backend Supabase tidak memvalidasi apakah user menempelkan sidik jari atau tidak. Backend hanya menerima Supabase JWT Session token.
3. **Session Revocation**: Jika user memilih logout dari Biometric Lock Screen atau gagal 3x, `authRepository.signOut()` dipanggil untuk memusnahkan refresh token dan session di Supabase SDK lokal.
4. **Biometric Change Invalidation**: Apabila OS melaporkan perubahan biometric enrollments (misal ada sidik jari orang lain didaftarkan ke HP), flag lokal dinonaktifkan otomatis dan aplikasi meminta login ulang Google secara penuh.

### 4.2 Kontrak Penyimpanan Preferensi (SharedPreferences Keys)

| Key | Tipe Data | Default | Keterangan |
|---|---|---|---|
| `bio_auth_enabled` | `bool` | `false` | Status aktivasi biometrik oleh user |
| `bio_auto_lock_timeout` | `int` | `1` | Timeout auto-lock saat background (dalam menit) |
| `bio_last_background_time` | `int` | `0` | Epoch milliseconds saat app masuk background |
| `bio_failed_attempts` | `int` | `0` | Counter jumlah kegagalan berturut-turut |
| `bio_prompt_offered` | `bool` | `false` | Menandai dialog aktivasi pertama kali sudah ditawarkan |

---

## 5. Arsitektur Flutter yang Diharapkan

### 5.1 Struktur Folder Modul Biometrik

```text
lib/features/biometric/
├── data/
│   ├── biometric_service.dart              # Adapter lokal ke plugin local_auth
│   └── biometric_preferences.dart          # Wrapper SharedPreferences
├── domain/
│   ├── biometric_type.dart                 # Enum: fingerprint, faceId, none
│   └── biometric_state.dart                # Sealed state class
└── presentation/
    ├── controllers/
    │   └── biometric_controller.dart       # StateNotifier / Notifier Riverpod
    ├── providers/
    │   └── biometric_providers.dart        # Riverpod providers
    ├── screens/
    │   └── biometric_lock_screen.dart      # Layar lock full screen
    └── widgets/
        ├── biometric_activation_sheet.dart # Bottom sheet tawaran aktivasi
        └── biometric_settings_tile.dart    # Komponen switch & timer di Settings
```

### 5.2 Service & Repository Contracts

#### BiometricService
```dart
abstract interface class IBiometricService {
  /// Cek apakah device memiliki hardware biometrik
  Future<bool> isHardwareSupported();

  /// Cek apakah ada biometrik yang sudah terdaftar di OS
  Future<bool> hasEnrolledBiometrics();

  /// Dapatkan tipe biometrik yang tersedia (Face ID, Fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Jalankan prompt autentikasi biometrik OS
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = true,
  });
}
```

#### BiometricAuthResult
```dart
sealed class BiometricAuthResult {
  const BiometricAuthResult();
}

final class BiometricAuthSuccess extends BiometricAuthResult {
  const BiometricAuthSuccess();
}

final class BiometricAuthFailed extends BiometricAuthResult {
  final String errorMessage;
  final bool isUserCanceled;
  final bool isLockedOut;
  const BiometricAuthFailed({
    required this.errorMessage,
    this.isUserCanceled = false,
    this.isLockedOut = false,
  });
}

final class BiometricAuthNotAvailable extends BiometricAuthResult {
  final String reason;
  const BiometricAuthNotAvailable(this.reason);
}
```

### 5.3 App Lifecycle Management

Integrasikan `WidgetsBindingObserver` di tingkat aplikasi (`lib/app.dart` atau wrapper widget `AppLifecycleLockManager`) untuk memantau transisi state:

```text
AppLifecycleState.paused / inactive:
  -> Simpan DateTime.now().millisecondsSinceEpoch ke `bio_last_background_time`

AppLifecycleState.resumed:
  -> Hitung elapsed = now - bio_last_background_time
  -> Jika isBiometricEnabled && (elapsed >= bio_auto_lock_timeout * 60 * 1000):
        Navigasi / Tampilkan BiometricLockScreen sebagai blocking overlay
```

---

## 6. Detail UX dan UI

Rujukan visual utama adalah `design/DESIGN.md`, `lib/core/theme/app_colors.dart`, `app_spacing.dart`, `app_radii.dart`, dan `app_motion.dart`.

### 6.1 Palet Warna & Visual Token

- **Primary**: `#0F766E` (`AppColors.primary`) — Tombol utama, icon aksen sensor.
- **Primary Dark**: `#115E59` (`AppColors.primaryDark`) — Header / Pressed states.
- **Accent Gold**: `#D99A2B` (`AppColors.accent`) — Highlight badge keamanan.
- **Background**: `#F8FAFC` (`AppColors.background`) — Background layar lock.
- **Surface**: `#FFFFFF` (`AppColors.surface`) — Kartu bottom sheet & dialog.
- **Text Primary**: `#17202A` (`AppColors.textPrimary`) — Judul & pesan utama.
- **Text Secondary**: `#64748B` (`AppColors.textSecondary`) — Keterangan panduan.
- **Error / Danger**: `#DC2626` (`AppColors.error`) — Feedback gagal, shake animation border.
- **Border Radii**: `AppRadii.card` (16px), `AppRadii.sheet` (24px top), `AppRadii.button` (12px).
- **Motion Durations**: `AppMotion.quick` (180ms) untuk button press, `AppMotion.standard` (300ms) untuk transisi/dialog.

### 6.2 Layar Kunci Biometrik (`BiometricLockScreen`)

Layar penuh yang tampil saat aplikasi terkunci (Cold start atau Background resume timeout).

```text
+-------------------------------------------------------+
|                                                       |
|                     [ 80x80 dp ]                      |
|                  ( Icon Family Lock )                 |
|                                                       |
|                     BANI RASIJAN                      |
|                   Arisan Keluarga                     |
|                                                       |
|            +─────────────────────────────+            |
|            |                             |            |
|            |      Aplikasi Terkunci      |            |
|            |  Sentuh sensor sidik jari   |            |
|            |    atau gunakan Face ID     |            |
|            |                             |            |
|            |        ((  [ ◉ ]  ))        |            |
|            |      [ Pindai Ulang ]       |            |
|            |                             |            |
|            | Percobaan tersisa: 3 dari 3 |            |
|            +─────────────────────────────+            |
|                                                       |
|             [ Masuk dengan Google ]                   |
|           (Fallback jika biometrik gagal)             |
|                                                       |
+-------------------------------------------------------+
```

**Komponen & Perilaku:**
1. **Auto-Trigger**: Saat layar dibuka, prompt biometrik OS otomatis terpicu satu kali.
2. **Sensor Icon Pulse**: Tombol icon sensor biometrik (Fingerprint / Face ID disesuaikan hardware) di tengah kartu dengan animasi denyut lembut (`AppMotion.standard`).
3. **Pesan Gagal & Shake Animation**: Jika pemindaian salah, kartu bergetar horizontal halus (shake $6$px, 3 siklus dalam 250ms), counter berkurang ("Percobaan tersisa: 2 dari 3"), border kartu berubah menjadi `AppColors.error`.
4. **Batas 3 Kali Gagal**:
   - Percobaan ke-3 gagal: Tampilkan pesan `"Batas percobaan tercapai. Silakan masuk ulang dengan Google."`.
   - Otomatis panggil `signOut()` dan arahkan user ke `LoginScreen`.
5. **Fallback Action**: Tombol sekunder bergaris/text button `"Masuk dengan Akun Google"` untuk fallback manual kapan saja.

### 6.3 Bottom Sheet Aktivasi Pasca Login (`BiometricActivationSheet`)

Ditampilkan setelah user berhasil login Google pertama kali, hanya jika perangkat mendukung biometrik dan fitur belum pernah ditawarkan.

```text
+-------------------------------------------------------+
|  ═════════════════════ [Handle] ════════════════════  |
|                                                       |
|       [ Icon Fingerprint/FaceID - Emerald Circle ]    |
|                                                       |
|             Aktifkan Kunci Biometrik?                 |
|                                                       |
|   Buka aplikasi lebih cepat dan aman menggunakan      |
|   sidik jari atau Face ID Anda tanpa login berulang.  |
|                                                       |
|   ✓ Akses instan saat membuka aplikasi                |
|   ✓ Otomatis terkunci saat ditinggalkan               |
|   ✓ Data biometrik tetap aman di perangkat Anda       |
|                                                       |
|   [ AKTIFKAN SEKARANG ]      (Primary Button - 52dp)  |
|   [ Nanti Saja ]             (Text Button - Secondary)|
|                                                       |
+-------------------------------------------------------+
```

**Perilaku:**
- Tombol **Aktifkan Sekarang**: Memicu verifikasi biometrik OS satu kali sebagai konfirmasi. Jika sukses, simpan `bio_auth_enabled = true`, tampilkan toast/snackbar sukses `AppColors.success`, lalu lanjutkan ke Home.
- Tombol **Nanti Saja**: Simpan `bio_auth_enabled = false` dan `bio_prompt_offered = true`, lalu langsung lanjutkan ke Home.

### 6.4 Integrasi pada Menu Pengaturan (`AdminSettingsScreen` / Profile)

Tambahkan section baru **Keamanan & Kunci Aplikasi** di layar pengaturan:

1. **Switch Kunci Biometrik**:
   - Label: `Kunci Sidik Jari / Face ID`
   - Subtitle: `Kunci aplikasi saat ditutup atau ditinggalkan`
   - Toggle on/off dengan prompt konfirmasi biometrik saat hendak mengaktifkan.
2. **Pilihan Waktu Kunci Otomatis (Dropdown / Modal Bottom Sheet)**:
   - Aktif hanya jika kunci biometrik ON.
   - Pilihan:
     - `Langsung saat keluar (0 detik)`
     - `Setelah 1 menit (Rekomendasi)`
     - `Setelah 2 menit`
     - `Setelah 5 menit`

### 6.5 Integrasi pada LoginScreen

1. Jika user memiliki session tersimpan dan `bio_auth_enabled == true`, tampilkan tombol cepat biometrik di bawah tombol Google:
   - `[ Icon Biometric ] Buka dengan Sidik Jari / Face ID`
2. Jika user menekan tombol tersebut, picu biometric prompt. Jika sukses, langsung arahkan ke Home.

---

## 7. Platform Configuration (Android & iOS)

### 7.1 Dependency `pubspec.yaml`

Gunakan versi `local_auth` resmi dan stabil yang kompatibel dengan Flutter SDK `>=3.4.0`:

```yaml
dependencies:
  local_auth: ^2.3.0
  # shared_preferences sudah ada (^2.5.5)
```

### 7.2 Android Configuration

#### 1. Activity Requirement (`MainActivity.kt`)
`local_auth` memerlukan `FlutterFragmentActivity` bukan `FlutterActivity` standar agar dialog `BiometricPrompt` dapat muncul tanpa crash.

Periksa dan sesuaikan `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
package com.example.arisan_rasijan // sesuaikan package name aktual

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

#### 2. Permissions (`android/app/src/main/AndroidManifest.xml`)
Tambahkan permission biometrik standar:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <!-- USE_FINGERPRINT otomatis di-handle oleh library untuk legacy Android API 23-27 -->
    
    <application
        android:label="Bani Rasijan"
        android:name="${applicationName}"
        ...>
        ...
    </application>
</manifest>
```

### 7.3 iOS Configuration

Tambahkan deskripsi penggunaan Face ID pada `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Aplikasi BANI RASIJAN membutuhkan akses Face ID untuk mengamankan dan membuka kunci aplikasi Anda.</string>
```

---

## 8. Urutan Implementasi

### Phase 0 — Setup Dependency & Platform
- [x] Tambahkan `local_auth: ^2.3.0` ke `pubspec.yaml` dan jalankan `flutter pub get`.
- [x] Ubah `MainActivity.kt` menjadi turunan `FlutterFragmentActivity`.
- [x] Tambahkan `USE_BIOMETRIC` di `AndroidManifest.xml`.
- [x] Tambahkan `NSFaceIDUsageDescription` di `Info.plist`.
- [x] Verifikasi build Android & iOS tidak mengalami konflik gradle / pod.

### Phase 1 — Data & Domain Layer
- [x] Buat enum `BiometricType` dan domain model `BiometricAuthResult`.
- [x] Implementasikan `BiometricPreferences` dengan `SharedPreferences`.
- [x] Implementasikan adapter `BiometricService` membungkus `LocalAuthentication`.
- [x] Buat unit test untuk `BiometricService` dan `BiometricPreferences` dengan mock plugin.

### Phase 2 — State Management (Riverpod)
- [x] Buat `BiometricState` (sealed class: `initial`, `authenticating`, `authenticated`, `failed`, `lockedOut`, `unavailable`).
- [x] Buat `BiometricController` mengelola logic counter kegagalan, timeout checking, dan background timestamp.
- [x] Buat providers: `biometricServiceProvider`, `biometricPreferencesProvider`, `biometricControllerProvider`.
- [x] Buat unit test untuk `BiometricController`.

### Phase 3 — UI Components & Animations
- [x] Buat `BiometricActivationSheet` dengan animasi modern dan styling Emerald/Gold.
- [x] Buat `BiometricLockScreen` lengkap dengan:
  - Header branding BANI RASIJAN
  - Icon biometric interaktif dengan pulse animation
  - Shake animation dan indikator sisa percobaan pada error
  - Tombol fallback Google Sign-In
- [x] Buat widget pengaturan `BiometricSettingsTile` untuk disematkan di menu Settings.
- [x] Buat widget test untuk seluruh komponen UI di atas.

### Phase 4 — App Integration & Lifecycle
- [x] Integrasikan `BiometricActivationSheet` pada callback post-login di `LoginScreen`.
- [x] Integrasikan pengecekan `BiometricLock` di `SplashScreen` sebelum navigasi ke Home.
- [x] Implementasikan lifecycle observer di `lib/app.dart` untuk memantau durasi background dan menampilkan `BiometricLockScreen` saat resume melebihi timeout.
- [x] Tambahkan menu pengaturan biometrik ke `AdminSettingsScreen` / profil setting.
- [x] Tambahkan tombol biometrik shortcut pada `LoginScreen` jika session valid.

### Phase 5 — Quality Assurance & Verification
- [x] Jalankan seluruh unit dan widget tests (`flutter test`).
- [x] Jalankan static analysis (`flutter analyze`) dan pastikan bersih tanpa warning.
- [x] Uji skenario cold start, background resume timeout, pembatalan biometrik, kegagalan 3x, dan fallback Google Auth.
- [x] Verifikasi tidak ada kebocoran session atau crash saat sensor tidak tersedia.

---

## 9. Test Plan

### 9.1 Unit Tests (`test/features/biometric/`)

| Test Case | Target | Expected Result |
|---|---|---|
| `check_hardware_support_returns_true` | `BiometricService` | Mengembalikan true jika hardware tersedia |
| `check_hardware_support_returns_false` | `BiometricService` | Mengembalikan false & tidak melempar uncaught exception |
| `authenticate_success` | `BiometricService` | Mengembalikan `BiometricAuthSuccess` |
| `authenticate_user_cancel` | `BiometricService` | Mengembalikan `BiometricAuthFailed(isUserCanceled: true)` |
| `preferences_save_and_load_enabled` | `BiometricPreferences` | Nilai boolean tersimpan dan terbaca presisi |
| `preferences_timeout_duration` | `BiometricPreferences` | Default 1 menit, dapat diubah ke 2, 3, 5 menit |
| `controller_increments_failed_attempts` | `BiometricController` | Counter bertambah tiap gagal; memicu lockout pada percobaan ke-3 |
| `controller_reset_failed_attempts` | `BiometricController` | Counter di-reset ke 0 saat autentikasi berhasil |
| `lifecycle_timeout_calculation` | `BiometricController` | Memvalidasi background duration melebihi ambang batas |

### 9.2 Widget Tests

| Test Case | Target Widget | Expected Result |
|---|---|---|
| `lock_screen_renders_branding_and_button` | `BiometricLockScreen` | Tampil teks BANI RASIJAN, icon sensor, tombol fallback |
| `lock_screen_displays_failed_attempt_counter` | `BiometricLockScreen` | Menampilkan "Percobaan tersisa: 2 dari 3" setelah 1x gagal |
| `lock_screen_triggers_google_fallback` | `BiometricLockScreen` | Menekan fallback memanggil navigasi / sign out |
| `activation_sheet_accept_flow` | `BiometricActivationSheet` | Menekan Aktifkan menyimpan preferensi true |
| `activation_sheet_dismiss_flow` | `BiometricActivationSheet` | Menekan Nanti Saja menyimpan preferensi false |
| `settings_tile_toggle_and_dialog` | `BiometricSettingsTile` | Switch toggle mengubah state dan menampilkan opsi timeout |

### 9.3 Manual Acceptance Scenarios

| Skenario | Langkah Pengujian | Expected Result |
|---|---|---|
| **Cold Start dengan Biometrik Aktif** | Buka app dari keadaan mati total | Splash screen cek session → Lock screen biometrik muncul → Scan berhasil → Masuk ke Home |
| **Resume dari Background (< Timeout)** | Buka app → Minimalkan selama 20 detik → Buka kembali | App langsung melanjutkan layar sebelumnya tanpa meminta biometrik |
| **Resume dari Background (> Timeout)** | Buka app → Minimalkan selama 2 menit → Buka kembali | App menampilkan Lock Screen biometrik → Scan berhasil → Layar kembali terbuka |
| **User Membatalkan Sensor OS** | Prompt biometrik muncul → Tekan Batal / Cancel | Lock screen tetap tampil dengan tombol "Pindai Ulang" dan tombol fallback Google Auth |
| **Gagal 3 Kali Berturut-turut** | Tempelkan jari yang salah 3 kali berturut-turut | Sesi Supabase lokal di-sign out, app menampilkan pesan lockout, user diarahkan ke LoginScreen |
| **Perangkat Tanpa Sensor Biometrik** | Jalankan di emulator tanpa fingerprint | Tidak ada tawaran aktivasi biometrik, app berjalan normal via Google Auth |
| **Matikan Fitur di Settings** | Buka Pengaturan → Matikan switch Biometrik → Restart app | App langsung masuk ke Home tanpa Lock Screen |

---

## 10. Acceptance Criteria

- **AC-01 — Device Capability Detection**: Aplikasi mendeteksi ketersediaan biometrik. Jika tidak tersedia, fitur tersembunyi tanpa error/crash.
- **AC-02 — Post-Login Opt-in**: Setelah login Google berhasil, user ditawarkan bottom sheet aktivasi biometrik satu kali. Pilihan tersimpan secara persisten.
- **AC-03 — Cold Start App Lock**: Jika fitur aktif dan session valid, aplikasi mewajibkan verifikasi biometrik sebelum user dapat mengakses Home.
- **AC-04 — Background Timeout Lock**: Jika app ditinggalkan di background melebihi konfigurasi timeout ($1$–$5$ menit), app mengunci layar saat di-resume.
- **AC-05 — Max 3 Failed Attempts**: Setelah 3 kali gagal berturut-turut, sesi lokal di-logout paksa dan user diarahkan ke Google Login.
- **AC-06 — Fallback Google Auth**: Tersedia tombol fallback untuk masuk via Google Sign-In kapan saja jika sensor biometrik bermasalah.
- **AC-07 — Settings & Configurable Timeout**: User dapat mengaktifkan/menonaktifkan fitur dan memilih timeout auto-lock di Pengaturan.
- **AC-08 — Security Separation**: Biometrik tidak digunakan sebagai autentikasi langsung ke server; Supabase RLS & JWT tetap menjadi sumber otoritas data.
- **AC-09 — UI/UX & Motion Consistency**: Menggunakan tema warna Emerald (`#0F766E`), Gold (`#D99A2B`), radii standar, dan animasi halus sesuai panduan `DESIGN.md`.
- **AC-10 — Zero Test & Analyzer Regressions**: Semua test unit/widget (existing + new) lolos dan `flutter analyze` bersih.

---

## 11. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| `MainActivity` bukan `FlutterFragmentActivity` | Crash instan saat dialog biometrik muncul di Android | Ubah `MainActivity.kt` ke `FlutterFragmentActivity` pada Phase 0 |
| Loop lock screen saat app berpindah ke background untuk system biometric prompt | Layar terkunci berulang kali tanpa henti | Gunakan flag `isAuthenticating` internal agar lifecycle observer tidak menganggap dialog OS sebagai backgrounding user |
| Session Supabase expired di server saat biometrik berhasil | Crash atau forbidden RLS request setelah lock screen terbuka | Validasi `currentSession` Supabase sebelum membuka kunci; jika expired, arahkan login ulang |
| Sidik jari baru ditambahkan ke perangkat OS oleh pihak ketiga | Potensi akses tidak sah | Konfigurasikan `invalidateOnEnrollment: true` (jika didukung platform) atau minta re-auth Google saat hash biometrik berubah |
| Timeout background terlalu sensitif saat user sekadar ganti app sesaat | UX terganggu karena sering terkunci | Beri default timeout yang wajar ($1$ menit) dan sediakan opsi konfigurasi di Settings |

---

## 12. Definition of Done

- [x] Dependency `local_auth` terpasang dan terkonfigurasi di Android & iOS.
- [x] Module `lib/features/biometric/` selesai (data, domain, presentation).
- [x] `BiometricLockScreen` dan `BiometricActivationSheet` terimplementasi dengan animasi dan styling `DESIGN.md`.
- [x] Lifecycle observer background timeout berfungsi di `lib/app.dart`.
- [x] Opsi pengaturan biometrik tersedia di menu Settings.
- [x] Fallback Google Sign-In dan limit 3x kegagalan terverifikasi.
- [x] Unit tests dan widget tests untuk biometrik selesai dan pass.
- [x] Seluruh test suite project (`flutter test`) pass tanpa regresi.
- [x] `flutter analyze` tidak menghasilkan error atau warning baru.
- [x] Dokumentasi `docs/ISSUE-5.md` terbit dan disetujui.

---

## 13. File yang Diperkirakan Berubah / Dibuat

### File Baru
- `docs/ISSUE-5.md`
- `lib/features/biometric/data/biometric_service.dart`
- `lib/features/biometric/data/biometric_preferences.dart`
- `lib/features/biometric/domain/biometric_type.dart`
- `lib/features/biometric/domain/biometric_state.dart`
- `lib/features/biometric/presentation/controllers/biometric_controller.dart`
- `lib/features/biometric/presentation/providers/biometric_providers.dart`
- `lib/features/biometric/presentation/screens/biometric_lock_screen.dart`
- `lib/features/biometric/presentation/widgets/biometric_activation_sheet.dart`
- `lib/features/biometric/presentation/widgets/biometric_settings_tile.dart`
- `test/features/biometric/data/biometric_service_test.dart`
- `test/features/biometric/presentation/controllers/biometric_controller_test.dart`
- `test/features/biometric/presentation/screens/biometric_lock_screen_test.dart`

### File yang Dimodifikasi
- `pubspec.yaml` (tambah `local_auth`)
- `android/app/src/main/kotlin/.../MainActivity.kt` (`FlutterFragmentActivity`)
- `android/app/src/main/AndroidManifest.xml` (`USE_BIOMETRIC`)
- `ios/Runner/Info.plist` (`NSFaceIDUsageDescription`)
- `lib/app.dart` (lifecycle lock manager)
- `lib/routing/app_router.dart` (rute `/biometric-lock`)
- `lib/features/splash/presentation/splash_screen.dart` (integrasi lock check)
- `lib/features/auth/presentation/screens/login_screen.dart` (post-login sheet & shortcut)
- `lib/features/settings/presentation/screens/admin_settings_screen.dart` (menu pengaturan biometrik)
