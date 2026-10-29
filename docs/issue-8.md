# Issue 8 — Backup Supabase dari Aplikasi Admin

**Status:** Migration/function diterapkan — test Flutter lulus; verifikasi worker tertunda  
**Area:** Admin → Backup  
**Referensi:** [`backup.md`](backup.md), [`DESIGN.md`](../design/DESIGN.md)

## Ringkasan

Bangun fitur bagi admin untuk meminta backup darurat Supabase dan memantau riwayatnya dari aplikasi Flutter. Aplikasi hanya membuat job dan membaca status; proses `pg_dump` serta penyalinan Storage tetap dijalankan oleh worker di server. Kredensial database, `service_role`, dan kunci S3 tidak boleh disimpan atau dikirim dari aplikasi.

## Tujuan

- Admin dapat meminta backup dengan cakupan **Lengkap** (database dan Storage) atau **Database saja**.
- Admin dapat melihat status job terbaru dan detail hasilnya, termasuk kegagalan.
- Perubahan status terlihat otomatis, dengan polling sebagai fallback saat Realtime tidak tersedia.
- Halaman mengikuti pola visual dan komponen aplikasi BANI RASIJAN.

## Batasan

- Menu dan halaman hanya ditampilkan kepada user dengan `profiles.role == 'admin'`, konsisten dengan role admin aplikasi. RLS dan Edge Function memverifikasi role yang sama di server.
- Tidak ada fitur restore, unduh backup, ubah jadwal, batalkan job, atau notifikasi push pada issue ini.
- Telegram dan eksekusi backup tetap tanggung jawab worker sesuai [`backup-worker.md`](backup-worker.md).
- Jangan menampilkan error mentah Supabase/PostgreSQL kepada pengguna.

## Prasyarat backend

Jalankan dan verifikasi tahap backend sebelum integrasi Flutter. Jangan menaruh secret server di aplikasi.

- [x] Buat tabel `public.backup_jobs`, constraint status/cakupan, dan unique partial index satu job aktif (`supabase/migrations/20261021024547_backup_jobs.sql`). Pengguna mengonfirmasi migration sudah dieksekusi manual di Supabase.
- [x] Terapkan RLS admin-only untuk baca dan cabut izin tulis client. Migration lanjutan menyelaraskan policy dengan `profiles.role` dan melarang anggota mengganti role sendiri; pengguna mengonfirmasi SQL sudah dieksekusi.
- [x] Tambahkan tabel ke publikasi Supabase Realtime. Realtime live belum diuji dengan perubahan status worker.
- [x] Implementasikan Edge Function `request-backup` dengan validasi JWT, role `profiles.role`, scope/catatan, insert service role, dan respons 201/401/403/409; pengguna mengonfirmasi function sudah dideploy ulang.
- [x] Function dideploy oleh pengguna di `https://iggwgsuvdtcowlypnglj.supabase.co/functions/v1/request-backup`; OPTIONS preflight ke endpoint membalas 200.
- [x] Tambahkan jadwal bulanan `pg_cron` (02:00 WIB tanggal 1) ke migration yang telah dieksekusi menurut konfirmasi pengguna. Jadwal belum diverifikasi lewat `cron.job`.
- [ ] Pastikan worker dapat mengambil serta memperbarui job. Jangan membuat atau mengubah kredensial produksi dari aplikasi.
- [x] Dokumentasikan langkah migrasi, setup/deploy Edge Function, jadwal, worker, payload invoke, dan verifikasi tanpa mencatat nilai secret di `backup.md`, `backup-worker.md`, dan issue ini.

## Pekerjaan Flutter

- [x] Periksa pola routing, state management Riverpod, Supabase client, komponen, theme token, dan test proyek; implementasi menggunakan pola serta komponen yang tersedia.
- [x] Tambahkan model `BackupJob` dan repository untuk riwayat 10 job, backup sukses terakhir, realtime, fallback polling, dan pemanggilan Edge Function.
- [x] Tambahkan menu Backup di Profil serta pemeriksaan metadata admin pada halaman.
- [x] Buat halaman Backup dengan banner backup terakhir, aksi utama, dan riwayat.
- [x] Tambahkan dialog scope/catatan dengan batas 200 karakter dan penjelasan Database saja.
- [x] Nonaktifkan aksi selama job aktif dan petakan status 401/403/409/error.
- [x] Tambahkan state loading/kosong/error/coba lagi, label status, dan indikator progres job running.
- [x] Segarkan banner pada sukses baru dan fallback polling 10 detik setelah stream error; timer dihentikan ketika tidak ada job aktif atau stream ditutup.
- [x] Tambahkan detail job dengan field yang diminta dan pesan error untuk job gagal.
- [x] Tampilkan waktu lokal dan ukuran backup dalam MB.

## Arahan desain dan aksesibilitas

- Ikuti `design/DESIGN.md`, `design/DESIGN_TOKENS.md`, dan `design/COMPONENTS.md`. Gunakan warna semantik dari theme, permukaan putih, border halus, radius card yang sudah dipakai, dan aksen teal secara terkendali. Hindari tampilan dashboard finansial yang padat.
- Gunakan tipografi proyek (Plus Jakarta Sans bila sudah tersedia), body 15–16 px, kontras kuat, label teks untuk aksi penting, serta target sentuh minimal 44–48 px.
- Pertahankan hierarki sederhana: status backup terakhir, aksi utama, lalu riwayat. Jangan mengandalkan warna saja untuk membedakan status.
- Buat layout adaptif berdasarkan lebar ruang tersedia; batasi lebar konten di jendela besar dan pastikan dialog/list tetap nyaman pada layar sempit serta saat text scaling.
- Gunakan motion ringan hanya untuk perubahan state (misalnya pergantian status/banner) mengikuti pola animasi proyek. Hormati `MediaQuery.disableAnimations`; jangan membuat animasi dekoratif yang menghambat pemantauan.
- Sediakan semantic label untuk ikon/status dan pertahankan navigasi keyboard bila platform mendukungnya.

## Pemanggilan Edge Function

Function membaca `scope` (`full` atau `db_only`) dan `note` opsional. Field `name` pada contoh invoke awal tidak digunakan; karena scope default adalah `full`, request tersebut tetap akan membuat job backup lengkap tanpa catatan.

```dart
final response = await supabase.functions.invoke(
  'request-backup',
  body: {'scope': 'full', 'note': 'Functions'},
);
final data = response.data;
```

## Teks dan pemetaan status

- Judul dialog: **Backup sekarang**.
- Cakupan: **Lengkap** dan **Database saja**.
- Bantuan Database saja: **Storage tidak diperbarui. Salinan storage tetap dari backup lengkap terakhir.**
- Sukses membuat job: **Job dibuat. Worker mengambilnya dalam ±1 menit.**
- 401: **Sesi berakhir, silakan login ulang**.
- 403: **Anda tidak punya akses untuk fitur ini**.
- 409: **Masih ada backup yang berjalan**.
- Error jaringan/server lain: **Gagal memulai backup. Coba lagi.**
- Status: `pending` = Menunggu; `running` = Berjalan; `success` = Berhasil; `failed` = Gagal.
- Banner menampilkan waktu sejak backup sukses terakhir; peringatan bila lebih dari 35 hari dan error bila belum pernah sukses.

## Kriteria penerimaan

- [ ] Admin dapat membuka halaman Backup; user non-admin tidak melihat akses dan ditolak juga oleh RLS/Edge Function (perlu jalankan migration otorisasi lanjutan dan deploy ulang function).
- [x] Dialog meminta cakupan dan catatan opsional; catatan dibatasi 200 karakter dan dikirim setelah trim.
- [x] Job baru muncul di riwayat setelah respons berhasil. Snackbar menyampaikan bahwa worker mengambilnya dalam ±1 menit.
- [x] Tombol nonaktif saat ada job pending/running; respons 409 menampilkan pesan yang ditetapkan.
- [x] Perubahan `pending → running → success/failed` tampil otomatis tanpa refresh manual, dan fallback polling bekerja saat Realtime gagal.
- [x] Banner menunjukkan backup sukses terakhir, peringatan untuk usia >35 hari, atau error jika belum ada backup sukses.
- [x] Detail riwayat memuat seluruh field yang disyaratkan; error job gagal dapat dibaca admin.
- [x] Tidak ada secret server atau error teknis mentah dari pemanggilan aplikasi yang masuk ke UI.
- [ ] Layout tidak overflow pada ukuran layar sempit dan lebar; kontrol utama memenuhi kebutuhan aksesibilitas.

## Pengujian yang harus dilakukan

- [x] Tulis dan jalankan unit test model: parsing nullable fields, konversi waktu lokal, status aktif, durasi, dan ukuran.
- [x] Tulis dan jalankan unit test repository dengan fake: batas/order query, last success, payload request, dan fallback polling setelah stream error.
- [x] Tulis dan jalankan widget test akses admin/non-admin, riwayat/banner, tombol nonaktif saat job aktif, dialog scope/catatan, dan detail.
- [x] Uji fallback polling dan penghentian timer saat tidak ada job aktif melalui unit test repository.
- [x] Jalankan formatter dan analyzer pada file yang disentuh serta seluruh test backup yang relevan; 11 test lulus dan analyzer melaporkan `No issues found`.
- [ ] Verifikasi end-to-end dengan backend/worker pada environment yang disetujui: request menjadi pending, worker mengambil job, status akhir success/failed, serta error 409 dan akses non-admin.
- [ ] Periksa UI pada lebar sempit dan lebar serta dengan text scaling; jika tersedia, validasi menggunakan MCP Dart/Flutter untuk analisis diagnostik dan konsistensi widget.

## Catatan implementasi

- Ikuti struktur fitur dan dependency injection yang sudah digunakan aplikasi. Jangan menyalin contoh kode dari `backup.md` secara mentah bila tidak sesuai versi package/pola proyek.
- Bila backend atau worker belum tersedia, implementasi Flutter tetap dapat diuji dengan repository fake; tandai verifikasi end-to-end sebagai tertunda beserta prasyarat yang belum tersedia.
- Untuk perubahan Supabase/Postgres, ikuti skill Supabase dan praktik Postgres proyek; migrasi, RLS, serta pengujian otorisasi merupakan bagian dari fitur, bukan validasi UI saja.
- Pengguna mengonfirmasi migration dijalankan manual dan function dideploy. OPTIONS endpoint membalas 200 dan POST tanpa JWT ditolak 401. Function belum dipanggil dengan JWT admin agar tidak membuat job backup produksi. Worker, RLS/Realtime live, dan jadwal cron belum diverifikasi end-to-end.
- `supabase projects list` dicoba memakai CLI login yang disebut tersedia, tetapi Supabase API menolak token dengan `Invalid access token`. Repo belum memiliki `supabase/config.toml`, dan sesi MCP Supabase/Dart tidak tersedia.
- Temuan lanjutan: menu profil sebelumnya memakai `profiles.role`, sedangkan halaman/RLS/function memakai `app_metadata.role`, sehingga admin aplikasi tertahan di halaman akses. Migration `20261021040000_backup_profile_admin_authorization.sql` dan function yang diperbarui menyamakan sumber role; pengguna mengonfirmasi SQL dan deploy function sudah diterapkan. Alur request memakai akun admin live masih perlu dicoba.
- Flutter test perlu dijalankan dengan akses ke SDK/cache di luar workspace; suite backup kini lulus 11 test. Otorisasi database dengan JWT admin/non-admin dan skenario worker masih perlu diverifikasi pada project live.
- [ ] Verifikasi job cron terdaftar, status job dapat dibaca realtime, dan worker mengubah status hingga sukses/gagal.
