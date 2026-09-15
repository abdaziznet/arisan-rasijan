# ISSUE-4: Implementasi Fitur Maps, Lokasi Rumah, dan Navigasi Arisan

**Status:** Implementation Complete — Pending Device/Production Verification  
**Prioritas:** High — MVP Enhancement  
**Scope:** Profil, Home, Maps/Navigasi, Permission, Supabase Schema, Testing, dan Release Configuration  
**Terkait:** `PRD.md`, `DATABASE_SCHEMA.md`, `ARCHITECTURE.md`, `DESIGN.md`, `UX_FLOW_PROFILE_MAPS.md`, `009_add_profile_location_fields.sql`

---

## 1. Tujuan

Menambahkan fitur lokasi rumah anggota dan navigasi ke rumah tuan rumah periode aktif. Anggota dapat menyimpan alamat rumah, mengambil latitude/longitude dari perangkat, melihat lokasi tuan rumah di Home, lalu membuka rute melalui Google Maps.

Fitur ini berfungsi sebagai pendukung koordinasi arisan keluarga. Aplikasi tidak membangun peta interaktif penuh dan tidak menyimpan riwayat pergerakan user.

### Hasil akhir yang diharapkan

1. Anggota dapat mengedit data alamat rumahnya sendiri.
2. Anggota dapat mengambil koordinat rumah menggunakan lokasi perangkat.
3. Permission lokasi ditangani dengan jelas pada semua kondisi.
4. Home menampilkan alamat tuan rumah periode aktif.
5. Tombol direction membuka Google Maps dengan tujuan yang valid.
6. Jika Google Maps tidak tersedia, browser menjadi fallback.
7. Fitur tetap dapat digunakan secara manual jika permission lokasi ditolak.
8. Data lokasi hanya tersedia bagi anggota keluarga yang telah login dan mengikuti RLS.

---

## 2. Panduan Eksekusi dan Standar Kualitas

### 2.1 Skills yang wajib digunakan

- `flutter-apply-architecture-best-practices` untuk pembagian UI, logic, dan data layer.
- `flutter-build-responsive-layout` untuk Home card dan form profil pada layar kecil.
- `flutter-add-widget-test` untuk pengujian interaksi form, permission state, dan tombol direction.
- `supabase` untuk perubahan schema, RLS, dan integrasi Supabase.
- `supabase-postgres-best-practices` sebelum menulis atau mengubah SQL migration/RLS.
- `frontend-design` untuk menjaga konsistensi dengan desain BANI RASIJAN.

### 2.2 Aturan implementasi

- Gunakan feature-first structure dan Riverpod sesuai `ARCHITECTURE.md`.
- Jangan mengakses controller fitur lain secara langsung; gunakan repository/provider contract.
- Jangan meminta permission lokasi saat startup atau saat membuka Home.
- Permission hanya diminta setelah user menekan `Ambil Lokasi Saat Ini`.
- Jangan menyimpan current location sebagai tracking atau history.
- Jangan menambahkan API key Google Maps jika fitur hanya membuka external navigation URL.
- Jangan menampilkan koordinat mentah sebagai informasi utama kepada user; koordinat hanya metadata/editable fallback.
- Semua state async harus memiliki `loading`, `data`, dan `error` state.
- Semua perubahan harus tetap kompatibel dengan Android dan iOS.

### 2.3 TDD dan standar verifikasi

- Tulis unit/widget test sebelum implementasi production code pada tiap slice.
- Cakup success, validation error, permission denied, permanently denied, invalid coordinate, missing destination, Maps unavailable, dan user cancellation.
- Jalankan `flutter test` untuk test suite yang relevan.
- Jalankan `flutter analyze` dan pastikan tidak ada error/warning baru.
- Uji deep link pada emulator/perangkat Android dan iOS jika tersedia.
- Checklist dokumen ini hanya boleh ditandai selesai setelah verifikasi benar-benar dijalankan.

---

## 3. Scope dan Batasan

### 3.1 In scope

- Field lokasi rumah pada `profiles`.
- Form profil untuk alamat lengkap, kota/kecamatan, latitude, longitude.
- Pengambilan lokasi perangkat satu kali atas aksi user.
- Validasi koordinat dan alamat.
- Tampilan lokasi tuan rumah pada Home.
- Tombol direction ke Google Maps.
- Fallback browser jika Google Maps tidak bisa dibuka.
- Permission handling Android/iOS.
- RLS agar user hanya mengubah profil sendiri.
- Unit test, widget test, analyzer, dan manual acceptance test.

### 3.2 Out of scope

- Integrasi turn-by-turn navigation di dalam Flutter app.
- Marker semua rumah anggota.
- Live location sharing.
- Geofencing.
- Location history atau background location.
- Reverse geocoding otomatis menjadi alamat lengkap.
- Route preview, estimasi waktu, dan navigasi turn-by-turn di dalam app.
- Integrasi Apple Maps sebagai provider khusus.
- Penyimpanan Google Maps API key.
- Perubahan proses kocokan, payment, atau gathering.

---

## 4. Kontrak Data dan Database

### 4.1 Kondisi schema saat ini

Tabel `public.profiles` sudah memiliki:

- `id`
- `full_name`
- `phone_number`
- `address`
- `photo_url`
- `role`
- `is_active`
- `has_won_before`
- `created_at`

Migration yang disiapkan pada [supabase/migrations/009_add_profile_location_fields.sql](../supabase/migrations/009_add_profile_location_fields.sql) menambahkan:

- `city text`
- `latitude double precision`
- `longitude double precision`
- `updated_at timestamptz not null default now()`
- constraint latitude `-90..90`
- constraint longitude `-180..180`
- trigger update `updated_at`

### 4.2 Keputusan data MVP

Gunakan lokasi profil host sebagai sumber lokasi Home:

```text
active_period.host_id
        -> profiles.id
        -> profiles.address, city, latitude, longitude
```

Kolom `arisan_periods.host_address` tetap dipertahankan sebagai snapshot/fallback alamat teks. Pada MVP, tidak perlu menambahkan `host_latitude` dan `host_longitude` ke `arisan_periods` karena koordinat dapat dibaca dari profil host. Penambahan snapshot koordinat menjadi pekerjaan lanjutan jika kebutuhan audit historis muncul.

### 4.3 Kontrak model

Buat atau sesuaikan model profil agar memiliki field nullable berikut:

```dart
class ProfileLocation {
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;
}
```

Aturan parsing:

- `latitude` dan `longitude` boleh `null`.
- Nilai numeric dari Supabase dapat berupa `int`, `double`, atau string numeric dan harus diparse aman.
- Nilai nonnumeric/di luar range menjadi validation error, bukan crash.
- Jangan memaksa data lama memiliki koordinat.
- `updated_at` dibaca sebagai ISO timestamp nullable untuk kompatibilitas data lama sebelum migration diterapkan.

### 4.4 Migration dan RLS

Sebelum deploy:

- Pastikan migration `009_add_profile_location_fields.sql` sudah berada pada urutan migration yang benar di environment Supabase.
- Jalankan migration pada local/staging terlebih dahulu.
- Verifikasi `profiles.updated_at` terisi untuk row lama.
- Verifikasi constraint menolak latitude di bawah `-90`/di atas `90` dan longitude di bawah `-180`/di atas `180`.
- Verifikasi trigger mengubah `updated_at` ketika profil diperbarui.
- Pastikan policy `UPDATE` tetap membatasi member ke `id = auth.uid()` dan admin tetap dapat mengelola profil sesuai policy yang ada.
- Jangan membuka akses anonymous atau public untuk data lokasi.
- Pastikan `SELECT` hanya berlaku untuk authenticated family members sesuai policy existing.

Jika policy existing tidak membedakan kolom sensitif, catat keputusan produk: pada fase MVP anggota login dapat melihat alamat host untuk kebutuhan arisan, tetapi tidak ada endpoint/public URL yang mengekspos lokasi tanpa auth.

---

## 5. Arsitektur Flutter yang Diharapkan

### 5.1 Struktur folder yang disarankan

```text
lib/features/profile/
├── data/
│   ├── profile_repository.dart
│   └── location_service.dart
├── domain/
│   └── profile_location.dart
└── presentation/
    ├── controllers/
    │   └── profile_controller.dart
    ├── providers/
    │   └── profile_providers.dart
    ├── screens/
    │   ├── profile_screen.dart
    │   └── edit_profile_location_screen.dart
    └── widgets/
        ├── profile_location_section.dart
        └── location_permission_sheet.dart

lib/features/maps/
├── data/
│   └── maps_launcher.dart
├── domain/
│   └── navigation_destination.dart
└── presentation/
    └── providers/maps_providers.dart
```

Nama folder boleh mengikuti struktur yang sudah ada apabila feature profile/settings saat ini sudah memiliki owner yang tepat. Hindari membuat dua sumber kebenaran untuk data profile.

### 5.2 Repository contract

Repository profile minimal harus menyediakan:

```text
getCurrentProfile()
updateOwnProfileLocation(location)
```

Persyaratan:

- Update hanya mengirim field yang memang diubah.
- Jangan mengirim `role`, `is_active`, atau `has_won_before` dari form member.
- Tampilkan error Supabase tanpa membocorkan token atau detail internal.
- Setelah update berhasil, invalidate provider profile/current member agar Home membaca data terbaru.

### 5.3 Location service contract

Service lokasi minimal harus menyediakan:

```text
checkPermission()
requestPermission()
getCurrentPosition()
```

Service harus mengubah hasil package/platform menjadi application result yang dapat diuji, misalnya:

```text
LocationResult.permissionGranted(position)
LocationResult.permissionDenied()
LocationResult.permissionPermanentlyDenied()
LocationResult.serviceDisabled()
LocationResult.failed(message)
```

Jangan membuat widget memanggil plugin lokasi langsung. Plugin harus diisolasi di data/core service agar mudah dimock pada test.

### 5.4 Maps launcher contract

Maps launcher menerima:

```text
destination latitude
 destination longitude
optional destination label
```

Perilaku:

1. Validasi tujuan.
2. Bangun URI Google Maps.
3. Coba buka URI navigation.
4. Jika tidak dapat dibuka, buka URL browser fallback.
5. Jika semua gagal, kembalikan error yang dapat ditampilkan UI.

Gunakan URI encoding yang aman. Jangan merakit query URL dengan string mentah tanpa encoding.

---

## 6. Detail UX dan UI

Rujukan visual utama adalah [docs/UX_FLOW_PROFILE_MAPS.md](UX_FLOW_PROFILE_MAPS.md) dan `DESIGN.md`.

### 6.1 Profile screen

Tambahkan section `Alamat Rumah` pada profil:

- alamat lengkap
- kota/kecamatan
- status lokasi: `Lokasi tersimpan`, `Belum tersedia`, atau `Perlu diperbarui`
- waktu pembaruan terakhir jika ada
- tombol `Edit Alamat`

Tampilkan koordinat dalam form edit, bukan sebagai informasi utama di card profil. Jika koordinat digunakan sebagai fallback manual, input harus diberi label yang jelas.

### 6.2 Edit location screen/form

Field:

- `Alamat lengkap` — required jika user ingin menyimpan alamat manual.
- `Kota/Kecamatan` — optional atau required sesuai kontrak form existing.
- `Latitude` — nullable tetapi wajib berpasangan dengan longitude.
- `Longitude` — nullable tetapi wajib berpasangan dengan latitude.

Action:

- `Ambil Lokasi Saat Ini`.
- `Simpan`.
- `Batal` atau back navigation tanpa kehilangan data tersimpan.

Validation:

- latitude harus berada di `-90..90`.
- longitude harus berada di `-180..180`.
- latitude dan longitude harus diisi berpasangan.
- alamat kosong tidak boleh menghapus alamat lama tanpa konfirmasi.
- tampilkan error dekat field dan summary error yang mudah dipahami.

### 6.3 Permission bottom sheet/dialog

Sebelum meminta permission OS, tampilkan penjelasan singkat:

> Aplikasi menggunakan lokasi satu kali untuk membantu mengisi koordinat alamat rumah. Lokasi tidak dilacak di latar belakang.

Action:

- `Lanjutkan` → minta permission OS.
- `Isi Manual` → tutup sheet dan biarkan form manual.
- `Batal` → kembali tanpa perubahan.

State yang wajib didukung:

- service lokasi mati
- permission belum diminta
- permission granted
- permission denied sementara
- permission permanently denied
- posisi gagal diambil/timeout
- user membatalkan flow

Untuk permanently denied, arahkan user ke Settings hanya setelah user memilih action tersebut. Jangan membuka Settings secara paksa.

### 6.4 Home active period card

Card periode aktif menampilkan:

- nomor periode
- tanggal acara
- nama tuan rumah
- alamat teks dari host profile atau `host_address`
- status `Lokasi tersedia` atau `Lokasi belum diatur`
- tombol icon direction dengan tooltip/semantic label `Buka arah ke rumah tuan rumah`

Aturan tampilan:

- Tombol direction aktif hanya jika latitude dan longitude tujuan valid.
- Jika koordinat tidak tersedia, jangan arahkan ke koordinat `0,0`.
- Alamat tetap terlihat meskipun direction disabled.
- Jangan menambah tinggi card secara tidak stabil ketika status berubah.
- Layout harus aman pada lebar layar kecil dan font scaling besar.
- Touch target icon minimal 44–48 px.
- Gunakan warna dan kontras yang konsisten dengan emerald/gold design system.

### 6.5 Feedback

Sediakan feedback untuk:

- lokasi berhasil diambil
- profil berhasil disimpan
- permission ditolak
- layanan lokasi mati
- data lokasi tidak valid
- Google Maps/browser tidak dapat dibuka
- error jaringan saat menyimpan

Gunakan snackbar/banner/dialog sesuai tingkat urgensi. Jangan menampilkan stack trace atau error database mentah.

---

## 7. Android dan iOS Configuration

### 7.1 Android

Update `android/app/src/main/AndroidManifest.xml` dengan permission lokasi yang dibutuhkan package yang dipilih:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

Jangan menambahkan background location permission karena fitur ini tidak melakukan tracking.

Verifikasi:

- permission muncul pada runtime, bukan hanya manifest.
- label aplikasi dan package identifier tetap benar.
- tidak ada permission berlebihan.
- Android emulator dapat mensimulasikan lokasi.
- Android 12+ tetap berjalan jika user hanya memberi approximate location.

### 7.2 iOS

Update `ios/Runner/Info.plist` dengan usage description lokasi yang menjelaskan penggunaan satu kali untuk mengisi koordinat alamat rumah.

Verifikasi:

- prompt permission menampilkan alasan yang mudah dipahami.
- tidak menambahkan background location capability.
- iOS simulator/perangkat dapat menguji lokasi atau fallback manual.
- aplikasi tidak crash jika permission ditolak.

### 7.3 Dependency

Tambahkan package hanya jika memang dibutuhkan dan kompatibel dengan project:

- package lokasi, misalnya `geolocator`, untuk permission dan current position.
- package URI launcher, misalnya `url_launcher`, untuk membuka Google Maps/browser.
- package `flutter_map` + `latlong2` untuk memilih titik rumah secara manual melalui peta OpenStreetMap.

Sebelum menambah dependency:

- cek versi Flutter/Dart dan package yang sudah terpasang.
- jalankan `flutter pub get`.
- cek Android/iOS minimum deployment requirements.
- update lockfile hanya sebagai konsekuensi dependency resmi.

---

## 8. Deep Link dan Fallback Maps

### 8.1 Destination priority

Gunakan urutan tujuan berikut:

1. `host latitude + host longitude` dari profile host.
2. `host_address` atau `profiles.address` sebagai fallback pencarian alamat.
3. Jika keduanya tidak tersedia, direction disabled dan user diberi pesan untuk melengkapi data host.

### 8.2 URL strategy

Implementasikan satu adapter, bukan URL logic di widget. Adapter harus mendukung:

- Google Maps navigation URI dengan koordinat tujuan.
- URL browser Google Maps sebagai fallback.
- encoding destination label/alamat.
- platform-specific open behavior jika diperlukan.

Catatan: current device location tidak perlu dikirim sebagai parameter manual jika Google Maps dapat memakai lokasi perangkat saat navigasi dimulai. Jangan mengambil current location hanya untuk membuka direction, kecuali kontrak library/platform benar-benar membutuhkannya.

### 8.3 Error handling

- `canLaunchUrl` false tidak boleh menyebabkan crash.
- Gagal membuka app harus mencoba browser.
- Browser fallback gagal harus menampilkan pesan actionable.
- Jangan retry tanpa batas.
- Logging hanya boleh menyimpan status/error teknis yang tidak memuat alamat sensitif secara berlebihan.

---

## 9. Urutan Implementasi

### Phase 0 — Discovery dan keputusan teknis

- [x] Konfirmasi package lokasi dan launcher yang kompatibel.
- [x] Konfirmasi migration 009 sudah diterapkan/siap diterapkan.
- [x] Konfirmasi profile repository/provider yang sudah menjadi source of truth.
- [x] Konfirmasi apakah `host_address` existing dipakai sebagai fallback.
- [x] Dokumentasikan platform minimum dan perilaku approximate location.

### Phase 1 — Schema dan domain

- [x] Review SQL dengan `supabase-postgres-best-practices`.
- [x] Jalankan migration pada local/staging. (Migration sudah dijalankan manual di Supabase oleh user.)
- [ ] Verifikasi constraint dan trigger pada database remote.
- [x] Update model profile/location dengan parsing nullable yang aman.
- [x] Tambahkan validation object untuk koordinat.
- [x] Tambahkan unit test parsing dan validation.

### Phase 2 — Profile location

- [x] Implementasikan `LocationService` adapter.
- [x] Implementasikan profile repository update.
- [x] Implementasikan provider loading-success-error.
- [x] Tambahkan section alamat pada Profile/Settings.
- [x] Tambahkan edit form dan validation.
- [x] Tambahkan permission explanation sheet.
- [x] Tambahkan unit/widget tests untuk permission explanation dan manual fallback.
- [x] Tambahkan map picker manual dengan pin dan konfirmasi koordinat.

### Phase 3 — Home destination

- [x] Ambil active period dan host profile melalui provider yang ada.
- [x] Buat destination mapper dengan priority coordinate lalu address.
- [x] Tambahkan status lokasi ke active period card.
- [x] Tambahkan direction icon button dan semantic label.
- [x] Pastikan layout responsif dan tidak overflow.
- [x] Tambahkan test untuk available/unavailable destination.

### Phase 4 — Maps launcher

- [x] Implementasikan URI builder teruji.
- [x] Implementasikan launcher app-first/browser-fallback.
- [x] Tambahkan handling invalid coordinate dan launch failure.
- [x] Tambahkan peta OpenStreetMap untuk penentuan titik manual.
- [ ] Uji Android emulator/perangkat dengan dan tanpa Google Maps.
- [ ] Uji iOS sesuai device/simulator yang tersedia.

### Phase 5 — Platform permission dan security review

- [x] Tambahkan Android manifest permission.
- [x] Tambahkan iOS usage description.
- [x] Pastikan tidak ada background location permission/capability.
- [x] Review RLS profile update dan select.
- [ ] Uji member tidak dapat mengubah profil member lain.
- [ ] Uji anonymous tidak dapat membaca lokasi.

### Phase 6 — QA dan release readiness

- [ ] Jalankan unit/widget tests.
- [ ] Jalankan `flutter analyze`.
- [ ] Uji font scaling dan layar kecil.
- [ ] Uji offline/network error ketika menyimpan.
- [ ] Uji migration di staging.
- [ ] Uji end-to-end: profile → permission → save → Home → direction.
- [ ] Update checklist issue dan release notes bila diperlukan.

---

## 10. Test Plan

### 10.1 Unit tests domain/data

Buat test minimal untuk:

- parsing profile dengan latitude/longitude `null`.
- parsing `int`, `double`, dan numeric string.
- parsing nilai invalid.
- latitude valid pada `-90`, `0`, `90`.
- longitude valid pada `-180`, `0`, `180`.
- latitude/longitude di luar range ditolak.
- hanya satu koordinat diisi ditolak.
- address fallback dipilih jika koordinat tidak tersedia.
- coordinate destination dipilih jika valid.
- URI Maps meng-encode alamat/label dengan benar.
- URI tidak dibuat untuk destination invalid.
- repository mengirim update ke row user yang benar.
- error Supabase dipetakan menjadi application error.

### 10.2 Widget tests profile

- section `Alamat Rumah` tampil.
- data existing tampil pada form.
- user dapat mengubah alamat dan menyimpan.
- tombol current location membuka permission explanation.
- permission granted mengisi latitude dan longitude.
- permission denied mempertahankan mode manual.
- permanently denied menampilkan action menuju Settings.
- service disabled menampilkan pesan yang dapat dipahami.
- loading mencegah double submit.
- save error tidak menghapus data form.
- success menampilkan feedback dan refresh provider.

### 10.3 Widget tests Home

- nama host, tanggal, dan alamat tampil.
- direction aktif jika destination valid.
- direction disabled jika koordinat tidak tersedia.
- alamat fallback tetap tampil tanpa koordinat.
- tap direction memanggil launcher contract.
- tombol memiliki semantic label.
- card tidak overflow pada layar sempit dan text scale besar.

### 10.4 Integration/manual tests

| Skenario | Expected result |
|---|---|
| Member menyimpan alamat dengan coordinate dari device | Profile tersimpan dan Home membaca data terbaru |
| User menolak permission | Form manual tetap dapat disimpan |
| User memilih permanently denied | App tidak crash dan memberi arahan ke Settings |
| Location service mati | Pesan jelas, user dapat kembali ke input manual |
| Google Maps terpasang | Navigation app terbuka dengan destination benar |
| Google Maps tidak terpasang | Browser fallback terbuka |
| Semua launcher gagal | Error ramah tampil, app tetap usable |
| Host belum punya koordinat | Alamat tampil, tombol direction disabled |
| Member mencoba update user lain | Ditolak oleh RLS |
| Anonymous membaca profile location | Ditolak oleh RLS |
| Network putus saat save | Error tampil, input user tetap aman |
| Android approximate location | Koordinat diterima jika valid |
| Rotasi/rebuild saat loading | Tidak terjadi double request atau kehilangan state |

---

## 11. Acceptance Criteria

### AC-01 — Profile location

- User login dapat membuka section alamat rumah.
- User dapat menyimpan alamat manual.
- User dapat menyimpan alamat dengan latitude/longitude.
- User dapat memperbarui data miliknya sendiri.
- User tidak dapat mengubah data profil user lain.

### AC-02 — Permission

- Permission tidak diminta sebelum user menekan action lokasi.
- Permission denied tidak memblokir input alamat manual.
- Permanently denied tidak menyebabkan crash.
- Tidak ada background tracking.
- Teks permission menjelaskan tujuan penggunaan lokasi.

### AC-03 — Home

- Home menampilkan tuan rumah, tanggal, dan alamat periode aktif.
- Tombol direction hanya enabled jika destination valid.
- UI tidak overflow pada perangkat kecil.
- Data lama tanpa koordinat tetap dapat ditampilkan.

### AC-04 — Maps

- Tap direction membuka Google Maps jika tersedia.
- Browser fallback digunakan jika Google Maps tidak tersedia.
- Invalid destination tidak membuka koordinat `0,0`.
- Semua kegagalan launch menampilkan feedback yang dapat dipahami.
- User dapat menentukan titik rumah dengan mengetuk peta.
- Pin dapat dipindahkan dengan memilih titik lain pada peta.
- Latitude dan longitude terisi otomatis setelah titik dikonfirmasi.
- Tombol simpan nonaktif sampai koordinat valid tersedia.

### AC-05 — Security

- Data hanya diproses dalam konteks authenticated family app.
- RLS tetap membatasi update owner/admin sesuai schema.
- Tidak ada public map endpoint atau exposed secret.
- Tidak ada location history yang tersimpan.

### AC-06 — Quality

- Unit dan widget tests untuk scope ini pass.
- `flutter analyze` bersih untuk file yang disentuh.
- Migration berhasil pada staging.
- Manual flow profile → Home → Maps berhasil pada target platform yang tersedia.

---

## 12. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| User menolak permission | Koordinat tidak tersedia | Sediakan input alamat manual dan status yang jelas |
| GPS tidak akurat di dalam rumah | Destination meleset | Izinkan edit koordinat manual dan tampilkan timestamp |
| Google Maps tidak terpasang | Navigasi gagal | Browser fallback |
| Profile host belum lengkap | Tombol direction tidak bisa dipakai | Tampilkan alamat fallback dan status lokasi belum tersedia |
| RLS terlalu longgar | Lokasi keluarga bocor | Uji policy authenticated/member/admin sebelum release |
| RLS terlalu ketat | Home gagal membaca host | Uji query member pada staging |
| Data lama tidak punya kolom baru | Parsing/runtime error | Nullable parsing dan migration backfill |
| Package permission berbeda antar platform | Build/runtime issue | Kunci versi package, cek changelog dan test Android/iOS |
| Update `updated_at` memicu konflik | Data profile tidak konsisten | Gunakan trigger server-side dan update field minimal |
| User menekan tombol berkali-kali | Request ganda | Disable action selama loading dan guard di controller |
| Alamat rumah sensitif tampil terlalu luas | Risiko privasi | Batasi akses authenticated family dan tampilkan hanya konteks arisan |

---

## 13. Definition of Done

- [ ] Scope tidak melampaui batasan issue.
- [ ] Migration/schema terverifikasi pada staging.
- [ ] Domain model, validation, repository, service, dan UI selesai.
- [ ] Android manifest dan iOS Info.plist dikonfigurasi.
- [ ] Permission tidak meminta background location.
- [ ] Profile flow manual dan GPS selesai.
- [ ] Home destination card dan direction selesai.
- [ ] Maps app-first/browser-fallback selesai.
- [ ] RLS owner/admin/anonymous sudah diuji.
- [ ] Unit tests pass.
- [ ] Widget tests pass.
- [ ] Integration/manual acceptance tests pass pada platform tersedia.
- [ ] `flutter analyze` tidak menghasilkan issue baru.
- [ ] Dokumentasi PRD, UX flow, dan schema tetap konsisten.
- [ ] Checklist issue di-update berdasarkan bukti verifikasi aktual.

---

## 14. File yang Diperkirakan Berubah

### Database dan dokumentasi

- `supabase/migrations/009_add_profile_location_fields.sql`
- `specification/PRD.md`
- `specification/DATABASE_SCHEMA.md` jika ada perubahan kontrak final
- `docs/UX_FLOW_PROFILE_MAPS.md`
- `docs/ISSUE-4.md`

### Flutter

- `pubspec.yaml` dan lockfile jika dependency baru diperlukan
- profile/settings feature yang menjadi owner data profile
- `lib/features/home/presentation/home_screen.dart`
- `lib/core/` untuk service/utility lokasi atau launcher jika mengikuti konvensi existing
- `lib/routing/` hanya jika screen baru memerlukan route
- test di `test/features/profile/`, `test/features/maps/`, dan `test/features/home/`

### Platform

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

Daftar file di atas adalah target review, bukan izin untuk mengubah semua file. Perubahan harus tetap minimal dan mengikuti owner abstraction yang sudah ada.

---

## 15. Catatan Deployment

1. Backup atau pastikan rollback plan untuk perubahan schema.
2. Apply migration pada local/staging sebelum production.
3. Pastikan app version yang membaca field baru dirilis setelah schema tersedia.
4. Karena field baru nullable, versi app lama tetap dapat membaca row profile tanpa koordinat.
5. Setelah release internal testing, pantau error permission, launch fallback, dan profile save.
6. Jangan menganggap fitur selesai hanya karena build berhasil; acceptance flow pada perangkat nyata tetap wajib dilakukan.
