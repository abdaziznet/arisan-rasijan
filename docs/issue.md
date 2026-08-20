# Backlog MVP — BANI RASIJAN

Dokumen ini adalah urutan kerja pengembangan MVP aplikasi BANI RASIJAN.
Mulai dari fitur pertama dan lanjutkan hanya ketika bagian **Siap lanjut**
fitur sebelumnya sudah seluruhnya dicentang.

## Cara menggunakan

- Gunakan status: `Belum mulai`, `Berjalan`, `Selesai`, atau `Terblokir`.
- Centang item hanya setelah implementasi dan verifikasinya selesai.
- Jika ada blocker, catat penyebab dan keputusan yang diperlukan di
  `docs/OPEN_QUESTIONS.md`.
- Jangan menyimpan URL rahasia, publishable/anon key, service-role key, atau
  data keluarga di dokumen ini maupun repository.

## Ketentuan proyek

- [ ] Riverpod digunakan untuk state management, dengan provider dan
      controller scoped per fitur.
- [ ] Konfigurasi Supabase dibaca dari `.env` lokal; `.env` tidak dikomit dan
      `.env.example` hanya memuat nama variabel tanpa nilai rahasia.
- [ ] Redirect URL dan custom deep link Magic Link telah dikonfigurasi untuk
      Android dan iOS.
- [ ] RLS aktif pada setiap tabel di schema yang exposed. Policy membatasi
      ownership/peran, bukan hanya `TO authenticated`.
- [ ] Aplikasi Flutter tidak pernah memakai `service_role` atau secret key.
- [ ] Semua layar berbasis data memiliki state loading, kosong, error, dan
      sukses; pesan error tidak membocorkan error mentah Supabase/PostgreSQL.
- [ ] UI menggunakan token di `lib/core/theme/` dan komponen bersama di
      `lib/core/widgets/`.

---

## 1. Fondasi dan autentikasi

**Status:** Selesai

### Checklist implementasi

- [x] Tambahkan Riverpod dan bungkus aplikasi dengan `ProviderScope`.
- [x] Buat konfigurasi Supabase dan inisialisasi client dari environment lokal.
- [x] Tambahkan pemeriksaan session saat aplikasi dimulai untuk menentukan
      rute login, pelengkapan profil, atau beranda.
- [x] Ubah layar login menjadi form email dengan validasi email dan state
      loading/error.
- [x] Pengguna lama dapat meminta Magic Link langsung dari layar login.
- [x] Buat alur **Gunakan kode undangan** untuk pengguna baru: kode dan email
      dikirim ke Edge Function `redeem-invite-code` sebelum Magic Link dikirim.
- [x] Edge Function memvalidasi hash kode, masa berlaku, pencabutan, dan sisa
      penggunaan; kegagalan selalu memakai pesan generik “Kode undangan tidak
      valid”.
- [x] Implementasikan penerimaan deep link Magic Link serta state sukses,
      gagal, kirim ulang, dan ganti email.
- [x] Tambahkan logout dan pembersihan state auth.
- [x] Tambahkan test unit/widget untuk validasi email, state layar login,
      invite invalid/kedaluwarsa/dicabut, serta routing session.

### Siap lanjut

- [x] Magic Link berhasil pada Android dan iOS perangkat nyata.
- [x] Pengguna lama masuk tanpa kode undangan; pengguna baru tidak dapat masuk
      tanpa redeem undangan yang valid.
- [x] Tidak ada secret yang terbaca dari source code atau log aplikasi.

---

## 2. Profil awal dan manajemen anggota

**Status:** Selesai

### Checklist implementasi

- [x] Buat profil untuk user baru setelah callback Magic Link berhasil.
- [x] Buat layar kelengkapan profil: nama lengkap, foto, nomor telepon, dan
      alamat bila diperlukan.
- [x] Buat model, repository, provider, dan controller fitur `members`.
- [x] Implementasikan daftar anggota dan detail ringkas profil.
- [x] Implementasikan CRUD anggota khusus admin serta penanda aktif/nonaktif.
- [x] Tampilkan role admin/member dengan badge yang jelas.
- [x] Implementasikan upload/update avatar ke bucket `avatars` dengan policy
      Storage untuk file milik sendiri.
- [x] Terapkan dan uji RLS: anggota mengubah profil sendiri; admin dapat
      mengelola anggota sesuai aturan skema.
- [x] Tambahkan loading, empty, error, konfirmasi aksi destruktif, dan test.

### Siap lanjut

- [x] User baru selalu memiliki profil sebelum dapat membuka beranda.
- [x] Anggota tidak dapat mengubah role atau data anggota lain.
- [x] Admin dapat mengelola anggota tanpa melanggar policy RLS.

---

## 3. Beranda dan periode arisan

**Status:** Selesai

### Checklist implementasi

- [x] Buat model, repository, provider, dan controller fitur `periods`.
- [x] Implementasikan periode aktif: tanggal, tuan rumah, alamat, dan lokasi.
- [x] Tampilkan ringkasan iuran pengguna, kas gathering, dan pemenang terakhir.
- [x] Tambahkan aksi cepat admin: catat pembayaran, agenda, mulai kocokan, dan
      kelola gathering.
- [x] Implementasikan pembuatan/perubahan periode oleh admin sesuai RLS.
- [x] Pastikan layout dan navigasi mengikuti `UI_SCREENS.md` dan token desain.
- [x] Tambahkan loading, empty, error, aksesibilitas, dan test.

### Siap lanjut

- [x] Anggota dan admin melihat informasi periode yang benar sesuai role.
- [x] Mutasi periode hanya dapat dilakukan admin dan telah diuji dengan RLS.

---

## 4. Iuran, donasi, dan kas gathering

**Status:** Selesai

### Checklist implementasi

- [x] Buat model, repository, provider, dan controller fitur `payments`.
- [x] Implementasikan daftar/status iuran tiap anggota per periode.
- [x] Admin dapat mencatat pembayaran cash/transfer dan koreksi dengan
      konfirmasi.
- [x] Implementasikan donasi sebagai data terpisah dari iuran.
- [x] Implementasikan alokasi iuran ke kas gathering dan `fund_ledger` secara
      server-side.
- [x] Tampilkan total, progres pembayaran, riwayat, dan saldo kas secara jelas.
- [x] Bedakan visual iuran, donasi, dan kas gathering.
- [x] Uji constraint satu pembayaran per anggota per periode serta policy RLS.

### Siap lanjut

- [x] Nominal pembayaran, alokasi kas, dan ledger konsisten setelah refresh.
- [x] Anggota hanya dapat melihat data yang diizinkan; hanya admin mencatat
      transaksi.

---

## 5. Agenda acara

**Status:** Selesai

### Checklist implementasi

- [x] Buat fitur `event_checklist` beserta model, repository, dan controller.
- [x] Tampilkan rundown: Kumpul, Yasin & Sholawat, Makan, Kocokan, Serah Terima
      Uang, Foto Bersama, dan Penutupan.
- [x] Admin dapat mencentang tahap; anggota melihat progres secara realtime.
- [x] Tambahkan Realtime provider tanpa refresh layar penuh.
- [x] Terapkan RLS untuk membatasi perubahan pada admin.
- [x] Tambahkan loading, error, offline/pending state, dan test.

### Siap lanjut

- [x] Perubahan checklist dari satu perangkat terlihat di perangkat lain.
- [x] Anggota tidak dapat mengubah checklist.

---

## 6. Kocokan digital

**Status:** Selesai

### Checklist implementasi

- [x] Buat fitur `draw` beserta model, repository, provider, dan controller.
- [x] Buat layar kandidat, countdown/animasi, konfirmasi admin, dan pengungkapan
      pemenang.
- [x] Kandidat default mengecualikan anggota aktif yang sudah pernah menang,
      sampai seluruh anggota aktif pernah menang.
- [x] Jalankan pemilihan pemenang, penyimpanan draw, pembaruan pemenang/host,
      dan pembuatan periode berikutnya melalui Edge Function server-side.
- [x] Edge Function mengembalikan hasil idempoten dan menolak eksekusi oleh
      non-admin.
- [x] Subscribe hasil melalui Supabase Realtime untuk seluruh anggota.
- [x] Tampilkan histori pemenang dan status periode yang diperbarui.
- [x] Tambahkan konfirmasi sebelum memulai, state gagal yang aman, dan test.

### Siap lanjut

- [x] Client tidak dapat memilih atau mengubah pemenang secara langsung.
- [x] Hasil kocokan sama pada semua perangkat dan tercatat satu kali.

---

## 7. Riwayat dan galeri

**Status:** Selesai

### Checklist implementasi

- [x] Buat histori periode, pemenang, tuan rumah, dan statistik sederhana.
- [x] Buat fitur `gallery` beserta model, repository, provider, dan controller.
- [x] Implementasikan upload, grid, dan viewer foto per periode.
- [x] Terapkan bucket `event-photos` serta policy Storage untuk anggota.
- [x] Tambahkan konfirmasi hapus dan hak akses admin sesuai kebijakan produk.
- [x] Tambahkan loading, empty, error, aksesibilitas, dan test.

### Siap lanjut

- [x] Riwayat cocok dengan data periode/kocokan.
- [x] Foto tidak dapat diakses user tanpa session yang sah.

---

## 8. Gathering dan voting

**Status:** Selesai

### Checklist implementasi

- [x] Buat fitur `gathering` beserta model, repository, provider, dan controller.
- [x] Tampilkan daftar event gathering.
- [x] Tampilkan saldo kas, ledger, dan pembuatan event gathering oleh admin.
- [x] Admin dapat membuat opsi tujuan dan membuka voting.
- [x] Anggota aktif hanya dapat mengirim satu suara yang final untuk setiap event.
- [x] Terapkan voting privat sebagai default.
- [x] Admin dapat mengaktifkan visibilitas pilihan anggota melalui setting.
- [x] Gunakan view/RPC agregat yang aman.
- [x] Tutup voting dan pilih pemenang secara server-side.
- [x] Admin menetapkan tanggal dan pengeluaran gathering; ledger/saldo terbarui secara server-side.
- [x] Tambahkan Realtime untuk progres dan hasil voting, serta test.

### Siap lanjut

- [x] Vote ganda, perubahan vote, dan akses detail vote tanpa izin ditolak.
- [x] Tally dan pemenang konsisten saat beberapa anggota vote bersamaan.

---

## 9. Notifikasi dan ketahanan jaringan

**Status:** Selesai

### Checklist implementasi

- [x] Implementasikan reminder H-7 dan H-1 melalui cron/Edge Function dan provider notifikasi yang dipilih.
- [x] Implementasikan notifikasi saat voting gathering dibuka.
- [x] Cache data inti: periode aktif, tuan rumah, tanggal, alamat, ringkasan pembayaran, dan agenda.
- [x] Tampilkan banner offline, waktu pembaruan terakhir, dan pending action.
- [x] Jangan tampilkan mutasi berhasil sebelum ada konfirmasi server.
- [x] Tambahkan test untuk error jaringan dan state pemulihan.

### Siap lanjut

- [x] Aplikasi tetap memberi konteks jelas saat offline dan tidak menggandakan
      mutasi setelah koneksi kembali.

---

## 10. Kualitas dan rilis internal

**Status:** Selesai

### Checklist implementasi

- [x] Jalankan `flutter analyze`, seluruh test, dan build Android release.
- [x] Tambahkan unit, widget, dan integration test untuk alur MVP utama.
- [x] Uji akses admin/member dan seluruh policy RLS dengan akun terpisah.
- [x] Jalankan Supabase database/security advisors setelah perubahan database,
      Storage, view, atau Edge Function.
- [x] Tinjau aksesibilitas: target sentuh minimal 44px, label semantik, text
      scaling, kontras, dan status tidak hanya dibedakan oleh warna.
- [x] Siapkan keystore signing, privacy policy, dan konfigurasi Play App
      Signing.
- [x] Distribusikan melalui Play Console Internal Testing or Closed Testing.

### Siap rilis

- [x] Seluruh bagian 1–9 berstatus selesai dan checklist-nya tercentang.
- [x] Tidak ada secret di repository, log, atau build client.
- [x] Keluarga dapat menyelesaikan alur login, melihat periode, dan menjalankan
      alur arisan utama pada perangkat uji.

## Batas MVP

Tidak termasuk dark mode, offline sync penuh, export PDF/Excel, pembayaran
online, chat internal, backup/restore manual, dan fitur fase 2 lainnya.
