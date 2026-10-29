# Issue 9 — Push Notification dengan Firebase Cloud Messaging

**Status:** Rencana pengembangan — belum diimplementasikan  
**Platform:** Flutter Android & iOS  
**Backend:** Supabase Edge Functions, PostgreSQL, dan Cron  
**Desain acuan:** [`design/DESIGN.md`](design/DESIGN.md)

## Tujuan

Melengkapi dua alur notifikasi yang saat ini masih berupa stub dengan push notification melalui Firebase Cloud Messaging (FCM): reminder jadwal arisan H-7/H-1 dan pemberitahuan saat voting gathering dibuka. Supabase tetap menangani data, pemicu, dan jadwal; FCM menjadi kanal pengiriman ke perangkat.

Issue ini hanya mendokumentasikan rencana kerja. Checklist implementasi dan konfigurasi di bawah masih belum dikerjakan.

## Temuan kondisi saat ini

- `supabase/functions/send-reminders/index.ts` belum mencari periode mendatang atau mengirim notifikasi.
- `supabase/functions/send-gathering-notification/index.ts` menerima payload tetapi belum mengirim push.
- Migration reminder dan trigger voting sudah ada, tetapi URL/konfigurasi pada migration reminder masih berupa placeholder. Trigger voting hanya menangani perubahan status ke `voting`; pastikan juga event yang dibuat langsung berstatus `voting` memicu notifikasi.
- `pubspec.yaml` belum memiliki `firebase_core` atau `firebase_messaging`; belum ditemukan konfigurasi Firebase untuk Android/iOS maupun alur registrasi token perangkat.
- Tabel `notifications` sudah ada untuk jenis `reminder_h7`, `reminder_h1`, dan `announcement`, tetapi belum menyediakan penyimpanan token perangkat.

## Cakupan notifikasi

| Jenis | Pemicu | Penerima | Isi minimum |
|---|---|---|---|
| Reminder H-7 | Periode aktif akan berlangsung dalam 7 hari menurut tanggal lokal Jakarta | Anggota aktif dengan perangkat terdaftar | Nama aplikasi, tanggal acara, tuan rumah, dan alamat bila tersedia |
| Reminder H-1 | Periode aktif akan berlangsung dalam 1 hari menurut tanggal lokal Jakarta | Anggota aktif dengan perangkat terdaftar | Nama aplikasi, tanggal acara, tuan rumah, dan alamat bila tersedia |
| Voting dibuka | Event gathering masuk status `voting`, termasuk ketika dibuat langsung dengan status tersebut | Anggota aktif dengan perangkat terdaftar | Judul gathering dan ajakan membuka voting |

Token yang tidak valid/kedaluwarsa harus ditandai atau dihapus agar tidak terus dikirimi pesan. Pengguna dapat memiliki lebih dari satu perangkat. Jangan mengirim reminder berulang untuk periode dan jenis reminder yang sama.

**Di luar cakupan issue ini:** pengumuman admin, hasil kocokan, hasil voting, perubahan pembayaran/jadwal, pengingat bacaan, kotak masuk notifikasi, dan notifikasi backup. Fitur tersebut perlu issue terpisah bila disepakati.

## Rencana implementasi

### A. Firebase dan aplikasi Flutter

- [ ] Daftarkan aplikasi Android dan iOS di satu Firebase project yang dipilih keluarga. Application ID Android dan Bundle ID iOS saat ini sama-sama `net.abdaziz.arisanbanirasijan`; verifikasi kembali sebelum konfigurasi.
- [ ] Ambil konfigurasi Firebase untuk kedua platform menggunakan Firebase CLI/FlutterFire sesuai alur resmi, lalu simpan pada lokasi yang dibutuhkan build. Pastikan tidak memasukkan credential server ke aplikasi.
- [ ] Tambahkan dan inisialisasi `firebase_core` serta `firebase_messaging` tanpa mengganggu urutan inisialisasi Supabase, deep link, dan lock screen biometrik.
- [ ] Minta izin notifikasi pada waktu yang tepat dengan penjelasan singkat; dukung izin ditolak, izin ditolak permanen, dan pengaktifan kembali melalui Settings perangkat.
- [ ] Ambil token FCM, tangani refresh token, lalu daftarkan token ke backend dengan identitas anggota dari sesi Supabase yang tervalidasi.
- [ ] Saat logout, lepaskan hubungan token perangkat dari akun yang keluar. Jangan menyimpan token FCM sebagai data profil publik.
- [ ] Tangani pesan saat aplikasi foreground, background, dan terminated. Tapping reminder membuka periode terkait; tapping voting membuka detail gathering terkait.
- [ ] Ikuti pola Riverpod dan feature-first yang sudah ada. Untuk UI izin/pengaturan, gunakan komponen bersama, warna/typography/spacing dari `lib/core/theme/`, label yang jelas, target sentuh 44–48 px, dan lebar konten responsif dengan batas lebar yang wajar. Hindari halaman atau animasi baru bila alur yang ada sudah cukup.
- [ ] Bila ada transisi UI, gunakan motion yang sudah berlaku di aplikasi dan hormati `MediaQuery.disableAnimations`; notifikasi tidak boleh bergantung pada animasi untuk menyampaikan informasi.

### B. Penyimpanan token dan keamanan Supabase

- [ ] Tentukan migrasi minimal untuk menyimpan beberapa token per anggota/perangkat, platform, waktu update, dan status aktif; tambahkan unique/index yang dibutuhkan untuk upsert dan pengiriman.
- [ ] Aktifkan RLS. Anggota hanya boleh mendaftarkan/menghapus token milik dirinya sendiri; pengiriman massal dan akses credential FCM hanya dilakukan backend tepercaya.
- [ ] Simpan credential/service account FCM sebagai Supabase Edge Function secret. Jangan menaruh service account JSON, private key, atau FCM server credential di Flutter, `.env` yang dibundel, SQL plaintext, log, atau repository.
- [ ] Gunakan FCM HTTP v1 dengan OAuth access token yang berumur pendek dari credential server-side; tangani respons FCM dan hapus/nonaktifkan token yang ditolak sebagai token tidak terdaftar.
- [ ] Batasi akses endpoint Edge Function. Untuk pemicu database/Cron, validasi autentikasi server-to-server dan jangan mengandalkan payload dari client sebagai bukti otorisasi.
- [ ] Pastikan proses pengiriman idempotent: satu reminder per periode/jenis dan satu notifikasi voting per event, termasuk retry atau Cron yang berjalan ulang.
- [ ] Tinjau tabel `notifications` yang sudah ada sebelum menambah tabel. Bila perlu catatan pengiriman per perangkat untuk idempotensi/diagnostik, buat skema sekecil mungkin dengan RLS dan retensi yang jelas.

### C. Lengkapi pemicu yang masih TODO

- [ ] Lengkapi `send-reminders`: validasi pemanggil Cron, cari periode upcoming untuk H-7/H-1 berdasarkan tanggal `Asia/Jakarta`, kirim ke token anggota aktif, dan catat hasil agar tidak duplikat.
- [ ] Periksa dan perbaiki jadwal Cron serta placeholder URL/secret yang sudah ada. Tetapkan satu acuan waktu dan uji batas pergantian hari Jakarta.
- [ ] Lengkapi `send-gathering-notification` menggunakan FCM HTTP v1 dan validasi payload event dari server.
- [ ] Perbaiki pemicu voting agar mencakup transisi menuju `voting` dari update maupun pembuatan event yang langsung berstatus `voting`; cegah kirim ulang saat status tidak berubah.
- [ ] Pastikan kegagalan FCM tidak membatalkan pembuatan periode, pembukaan voting, atau transaksi bisnis utama. Catat kegagalan dengan aman dan sediakan mekanisme retry yang idempotent.

### D. Konfigurasi Firebase manual

Checklist ini perlu dikerjakan oleh pemilik akses Firebase/Apple Developer saat implementasi. Project ID belum ditentukan dan tidak dibuat pada tahap penulisan issue ini.

1. [ ] Pilih Firebase project keluarga yang sudah ada atau buat project baru; catat **Project ID** yang akan dipakai.
2. [ ] Tambahkan aplikasi Android ke project dengan package ID `net.abdaziz.arisanbanirasijan`.
3. [ ] Tambahkan aplikasi iOS ke project dengan bundle ID `net.abdaziz.arisanbanirasijan`.
4. [ ] Unduh konfigurasi aplikasi melalui CLI resmi, bukan menyimpan file manual dari chat: gunakan `npx -y firebase-tools@latest apps:sdkconfig ANDROID <APP_ID> --project <PROJECT_ID>` dan perintah serupa untuk `IOS`; ikuti kebutuhan output FlutterFire project saat integrasi.
5. [ ] Untuk iOS, siapkan Apple Developer account dan perangkat iPhone fisik untuk pengujian push. Buat APNs Authentication Key (.p8), simpan Key ID/Team ID, unggah key ke Firebase Console → Project settings → Cloud Messaging, lalu aktifkan capability Push Notifications pada target aplikasi iOS.
6. [ ] Pastikan Firebase Cloud Messaging API aktif untuk project tersebut.
7. [ ] Buat service account khusus pengiriman FCM dengan hak minimum yang diperlukan. Buat private key JSON hanya bila metode autentikasi yang dipilih membutuhkannya; simpan di password manager yang disetujui dan jangan commit file tersebut.
8. [ ] Masukkan Project ID dan credential yang diperlukan ke Supabase Edge Function Secrets melalui kanal admin yang aman. Jangan menaruh nilai secret di migration atau aplikasi Flutter.
9. [ ] Konfirmasi konfigurasi Android 13+ meminta izin runtime, channel notifikasi Android memiliki ID/nama yang stabil, dan aplikasi menggunakan ikon notifikasi yang sesuai brand.
10. [ ] Setelah konfigurasi, lakukan pengiriman uji ke token perangkat Android dan iOS fisik. Emulator iOS tidak cukup untuk membuktikan pengiriman APNs end-to-end.

## Pengujian yang wajib saat implementasi

- [ ] Unit test: parsing jenis/payload notifikasi dan routing tujuan (periode atau gathering).
- [ ] Unit test backend: pemilihan periode H-7/H-1 untuk zona `Asia/Jakarta`, penerima anggota aktif, periode yang sudah lewat, dan idempotensi Cron.
- [ ] Unit test backend: event voting yang baru dibuat sebagai `voting`, transisi status ke `voting`, status non-voting, token kedaluwarsa/tidak valid, serta sebagian pengiriman gagal.
- [ ] Flutter widget test: izin belum diminta, izin diterima, ditolak, dan state token/error; gunakan mock sesuai pola test repo.
- [ ] Integration/device test pada Android dan iOS fisik: foreground, background, terminated, tap notifikasi ke layar yang benar, token refresh, logout, dan izin notifikasi dimatikan.
- [ ] Regression: jalankan seluruh test Flutter yang relevan, `flutter analyze`, uji Edge Functions/migrasi di environment lokal/staging, serta smoke test login OTP, deep link auth, biometrik, periode, kocokan, gathering/voting, dan backup.
- [ ] Jangan menganggap uji emulator sebagai bukti APNs atau pengiriman FCM produksi; lakukan verifikasi perangkat nyata sebelum rilis.

## Acceptance criteria

- [ ] Perangkat Android dan iOS yang mengizinkan notifikasi menerima reminder H-7 dan H-1 satu kali per periode.
- [ ] Anggota aktif menerima push ketika voting gathering dibuka, termasuk event yang dibuat langsung dengan status `voting`.
- [ ] Tap notifikasi membawa pengguna ke konteks periode/gathering yang tepat setelah autentikasi; jika sesi belum ada, alur login tetap berfungsi lalu navigasi dilanjutkan dengan aman.
- [ ] Izin ditolak, token tidak tersedia, atau layanan FCM gagal tidak membuat aplikasi crash atau merusak transaksi arisan.
- [ ] Token dan credential hanya dapat diakses sesuai batas keamanan; token akun yang logout tidak lagi menjadi target pengiriman akun tersebut.
- [ ] Tidak ada pengiriman duplikat saat Cron/trigger diulang dan seluruh regression checks lulus.

## Referensi

- [`specification/PRD.md`](specification/PRD.md) — reminder H-7/H-1 dan alur voting gathering.
- [`specification/ARCHITECTURE.md`](specification/ARCHITECTURE.md) — Supabase Edge Function + Cron dengan FCM sebagai delivery channel.
- [`design/DESIGN.md`](design/DESIGN.md) — sistem visual, aksesibilitas, UI notifikasi, dan pengalaman jaringan lemah.
- [Firebase setup for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Receive FCM messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Send messages using FCM HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api)
