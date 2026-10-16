# Issue 7 — Privasi dan Verifikasi Donasi

**Status:** Implementasi selesai — siap direview
**Area:** Iuran/Donasi → tab Donasi

## Ringkasan

Perbaiki alur donasi agar member hanya dapat melihat riwayat donasinya sendiri. Daftar donatur dan nominal donasi anggota lain tidak boleh ditampilkan kepada member. Admin bertugas memeriksa pembayaran dan mengesahkan bahwa dana benar-benar sudah diterima.

Alur donasi menyediakan metode **Tunai**, **Transfer**, dan **QRIS**. Donasi yang baru dilaporkan atau menunggu pembayaran belum dianggap sah/diterima. Status hanya menjadi **Terverifikasi** setelah admin mengonfirmasi penerimaan berdasarkan uang tunai yang diterima atau catatan transaksi yang cocok.

## Temuan kondisi saat ini

- Layar donasi menampilkan daftar donasi periode dan ringkasan agregat, termasuk daftar item donasi.
- Form donasi saat ini meminta nominal dan catatan, tetapi tidak meminta metode pembayaran.
- Skema `donations` saat ini tidak memiliki metode pembayaran atau status verifikasi.
- Policy `donations_select_all` mengizinkan setiap pengguna yang login membaca seluruh baris donasi. Menyembunyikan daftar hanya di UI tidak cukup; akses database juga perlu dibatasi.
- Policy insert saat ini hanya mengizinkan admin membuat baris donasi. Alur submit oleh member perlu disesuaikan dengan keputusan produk dan policy database.

## Tujuan

- Member hanya melihat status dan riwayat donasi miliknya sendiri.
- Admin mendapat antrean donasi yang perlu diperiksa, bukan sarana untuk mengubah laporan member tanpa jejak.
- Dana yang belum diterima atau belum cocok tidak dihitung sebagai donasi terverifikasi.
- Menyediakan pencatatan penerimaan untuk tunai, transfer, dan QRIS.
- Perubahan status dapat ditelusuri: siapa yang memverifikasi, kapan, nominal berapa, dan catatan pemeriksaannya.

## Alur member

1. Member membuka tab **Donasi** dan melihat riwayat miliknya sendiri, ringkasan nominal miliknya, serta status setiap donasi.
2. Member memilih **Tambah Donasi**, mengisi nominal, memilih metode pembayaran, dan dapat menambahkan catatan atau bukti pendukung.
3. Aplikasi menyimpan laporan dengan status yang sesuai, bukan langsung menyatakannya diterima.
4. Setelah admin memeriksa pembayaran, status pada riwayat member diperbarui menjadi **Terverifikasi**, **Perlu diperiksa**, atau **Ditolak**. Tampilkan alasan/catatan yang relevan kepada member.

Member tidak dapat melihat nama, identitas, nominal, catatan, atau bukti pembayaran milik anggota lain. Tidak ada papan peringkat atau total publik per donatur.

## Alur pembayaran dan verifikasi admin

### Tunai

1. Member memilih **Tunai** dan melaporkan nominal yang akan/diserahkan.
2. Sebelum uang diserahkan, status tetap **Menunggu pembayaran**.
3. Admin menerima dan menghitung uang secara langsung, lalu mencocokkan nominal dengan laporan.
4. Admin mencatat nominal diterima dan menekan **Konfirmasi diterima**. Status menjadi **Terverifikasi**.
5. Bila belum diterima atau jumlah berbeda, admin membiarkan status menunggu atau menandai **Perlu diperiksa**, mencatat jumlah aktual dan alasannya.

### Transfer bank

1. Aplikasi menampilkan informasi rekening tujuan yang dikelola admin.
2. Member memasukkan nominal pokok donasi, misalnya **Rp25.000**.
3. Sistem mereservasi kode unik tiga digit dari **001–150** untuk laporan pembayaran tersebut. Contoh: kode `037` menghasilkan nominal bayar **Rp25.037**. Member melihat nominal pokok, kode unik, dan **nominal bayar tepat** yang harus dibayarkan.
4. Member melakukan transfer sesuai nominal tepat, lalu laporan menjadi **Menunggu verifikasi**. Referensi transaksi dan bukti transfer dapat disertakan sebagai bantuan pencocokan.
5. Admin mencocokkan nominal transfer dan transaksi dengan mutasi rekening. Bukti unggahan membantu pencarian, tetapi tidak menjadi satu-satunya bukti penerimaan.
6. Jika cocok, admin mencatat nominal diterima dan mengesahkan donasi. Jika belum ditemukan atau nominal berbeda, admin meminta klarifikasi atau menandai **Perlu diperiksa** dengan catatan.

Kode unik wajib digunakan untuk **transfer bank dan QRIS** pada MVP. Tunai tidak memerlukan kode. Untuk QRIS statis, aplikasi menampilkan nominal yang sudah ditambah kode dan menginstruksikan member memasukkan nominal itu saat membayar. Jika memakai QRIS dinamis, nominal berkode harus dikirim sebagai nominal tagihan saat QR dibuat. Admin mencocokkan pembayaran pada catatan transaksi/settlement merchant.

### Aturan reservasi kode unik

- Kode harus direservasi di server/database secara atomik ketika laporan transfer atau QRIS dibuat; jangan memilih kode hanya di aplikasi karena dua perangkat dapat memilih angka sama pada saat bersamaan.
- Jangan berikan kode yang sama kepada dua pembayaran transfer/QRIS yang sama-sama **Menunggu pembayaran**, **Menunggu verifikasi**, atau **Perlu diperiksa** dalam ruang lingkup rekening/merchant tujuan yang sama. Reservasi kode bersifat lintas metode transfer dan QRIS untuk tujuan tersebut. Terapkan constraint/locking database agar keunikan tetap berlaku pada request bersamaan.
- Kode dapat dilepas setelah donasi terverifikasi atau setelah laporan kedaluwarsa/dibatalkan. Masa berlaku perlu ditentukan; setelah lewat masa berlaku, transfer yang terlambat harus ditangani admin sebagai pengecualian dan tidak otomatis dipasangkan ke laporan baru.
- Rentang 001–150 berarti maksimal **150 reservasi aktif** untuk ruang kode yang sama. Jika semua kode masih terpakai, sistem harus meminta member menunggu atau admin menyelesaikan/membatalkan laporan kedaluwarsa. Jangan memakai ulang kode aktif.
- Kode unik berlaku pada ruang lingkup rekening tujuan yang sama. Jika ada beberapa rekening, ruang lingkup dan constraint harus mencakup rekening tujuan.
- Kode ini membantu pencocokan, tetapi bukan bukti pembayaran. Admin tetap mengesahkan berdasarkan mutasi rekening.
- Contoh perhitungan: nominal pokok Rp25.000 + kode 037 = nominal transfer/QRIS Rp25.037. Kode 150 menghasilkan Rp25.150. Simpan nominal pokok, kode, dan nominal bayar sebagai nilai terpisah agar riwayat dan rekonsiliasi jelas.
- Kode unik tidak dengan sendirinya menjamin **nominal total transfer** berbeda jika nominal pokok antar-member bervariasi. Contohnya, Rp25.037 dapat berasal dari pokok Rp25.000 + kode 037, atau Rp24.900 + kode 137. Karena itu, pencocokan tetap memakai rekening pengirim/waktu/referensi jika tersedia, dan sistem tidak boleh menganggap nominal total sebagai identitas transaksi yang pasti.
- Jika produk mensyaratkan setiap nominal transfer aktif berbeda secara global, perlu aturan tambahan (misalnya reservasi nominal total/validasi collision) dan kemungkinan menolak atau meminta nominal pokok lain saat terjadi bentrok. Ini berbeda dari sekadar memastikan kode 001–150 tidak dipakai ulang.

### QRIS

1. Aplikasi menampilkan gambar QRIS resmi dan instruksi pembayaran. Gambar QRIS hanya dapat diunggah/diganti admin melalui **Pengaturan Donasi**. QRIS statis perlu instruksi yang jelas untuk memasukkan nominal; nominal tidak diasumsikan berasal dari QR itu sendiri.
2. Member membayar dan melaporkan nominal serta bukti/referensi opsional.
3. Status menjadi **Menunggu verifikasi**.
4. Admin mencocokkan transaksi pada kanal/merchant QRIS dan catatan settlement yang tersedia.
5. Jika cocok, admin mencatat nominal diterima dan mengesahkan donasi. Jika belum terlihat atau jumlah berbeda, status **Perlu diperiksa** dan admin menambahkan catatan.

Integrasi notifikasi pembayaran otomatis dapat menjadi pengembangan berikutnya. Pada MVP, verifikasi QRIS dilakukan manual terhadap catatan transaksi/settlement merchant; screenshot pembayaran saja tidak mengesahkan dana.

## Status yang diusulkan

- **Menunggu pembayaran** — laporan dibuat, tetapi pembayaran belum dinyatakan dilakukan/diterima.
- **Menunggu verifikasi** — member menyatakan sudah membayar; admin belum mencocokkan penerimaan.
- **Perlu diperiksa** — data belum cocok, pembayaran belum ditemukan, atau ada selisih; alasan terlihat oleh member.
- **Terverifikasi** — admin telah mengonfirmasi dana diterima secara sah.
- **Ditolak** — laporan tidak dapat disahkan; alasan wajib dicatat dan ditampilkan kepada member.
- **Kedaluwarsa** — reservasi transfer/QRIS yang belum dibayar melewati 24 jam; kode dilepas dan pembayaran terlambat harus diperiksa admin secara manual.

Kolom `donations.amount` yang sudah ada digunakan sebagai nominal pokok yang dilaporkan. Simpan `received_amount` (nominal aktual yang diterima) terpisah, dan gunakan `payment_amount` sebagai nominal yang harus dibayar setelah penambahan kode unik untuk transfer/QRIS. Status **Terverifikasi** hanya dapat diberikan admin dan memerlukan waktu verifikasi serta identitas pemeriksa. Riwayat perubahan status disimpan sebagai jejak audit.

## Pemetaan schema Supabase

Migrasi `20261016000000_donation_payment_verification_and_qris.sql` menambahkan dukungan database untuk alur ini:

- `donations`: `payment_method`, `status`, `received_amount`, `unique_code`, `payment_amount` (kolom terhitung), `payment_reference`, `payment_proof_path`, `verified_by`, `verified_at`, dan `verification_note`. Baris donasi lama dipertahankan sebagai riwayat berstatus terverifikasi; baris baru menunggu pembayaran.
- Kode unik direservasi oleh trigger database dari rentang 001–150 dan dipakai bersama transfer/QRIS. Index unik parsial mencegah kode aktif terduplikasi; kode dilepas untuk laporan yang sudah final.
- `donation_payment_settings`: rekening, instruksi pembayaran, dan path gambar QRIS. Member dapat membaca pengaturan aktif; hanya admin dapat mengubahnya.
- Storage `donation-settings`: gambar QRIS yang dapat dibaca untuk keperluan pembayaran, dengan upload/ganti/hapus khusus admin.
- Storage `donation-proofs`: bucket privat untuk bukti pembayaran; akses dibatasi pada member pemilik laporan dan admin.
- RLS donasi membatasi member ke baris miliknya sendiri; hanya admin dapat memverifikasi atau mengubah nominal yang diterima. Member dapat membuat laporan sendiri dan melampirkan referensi/bukti tanpa mengubah data verifikasi.

## Kebutuhan layar admin

- Antrean verifikasi dengan filter metode, status, dan tanggal.
- Detail laporan: periode, member, nominal yang dilaporkan, metode, waktu, referensi/bukti, serta status.
- Aksi **Terverifikasi**, **Perlu diperiksa**, dan **Tolak** dengan konfirmasi/catatan yang sesuai.
- Saat mengesahkan, admin mengisi nominal yang benar-benar diterima. Selisih dari nominal laporan harus ditampilkan jelas.
- Tampilkan pemeriksa dan waktu verifikasi serta riwayat perubahan status.
- Admin memverifikasi penerimaan; admin tidak menghapus atau diam-diam mengganti laporan awal.
- Menu **Pengaturan Donasi** khusus admin untuk mengunggah/mengganti gambar QRIS dan mengatur nama bank, nama pemilik rekening, nomor rekening tujuan, serta instruksi pembayaran. Hanya admin yang dapat mengubah atau mengganti rekening tujuan; member hanya dapat membaca informasi pembayaran aktif.

## Privasi dan otorisasi

- Member hanya dapat membaca donasi yang `member_id`-nya terhubung ke profil member tersebut.
- Admin dapat membaca antrean donasi untuk verifikasi.
- Hanya admin dapat mengubah status verifikasi dan mengisi nominal diterima/catatan pemeriksaan.
- Bila member dapat mengirim laporan donasi sendiri, izinkan insert terbatas untuk identitas dirinya; member tidak boleh memilih member lain, mengesahkan status sendiri, atau mengubah data setelah dikirim kecuali lewat mekanisme revisi yang tercatat.
- Donasi anonim atau donasi yang dicatat admin tanpa member tidak ditampilkan ke riwayat member mana pun; hanya admin yang dapat melihatnya.
- Terapkan pembatasan di Supabase RLS dan validasi server/database, bukan hanya dengan memfilter data di Flutter.
- Bukti pembayaran bersifat privat dan hanya dapat diakses member pemilik serta admin yang berwenang.
- Gambar QRIS adalah materi pembayaran yang dapat dilihat member, tetapi aksi unggah/ganti/hapus dibatasi untuk admin di menu Pengaturan Donasi dan juga dikunci oleh Storage RLS.
- Nomor rekening tujuan dan informasi rekening lain hanya dapat diatur admin melalui Pengaturan Donasi; database menolak perubahan dari member.

## Cakupan MVP

- [x] Tambahkan pilihan metode Tunai, Transfer, dan QRIS pada form donasi.
- [x] Untuk transfer dan QRIS, tambahkan reservasi kode unik 001–150 dan tampilkan nominal bayar tepat; cakupan reservasi lintas kedua metode pada rekening/merchant tujuan yang sama.
- [x] Tetapkan masa berlaku reservasi kode 24 jam; kode dilepas otomatis dan pembayaran terlambat harus diverifikasi admin secara manual. Jika 150 kode sedang terpakai, aplikasi menampilkan kegagalan reservasi.
- [x] Buat status pembayaran/verifikasi beserta nominal dilaporkan dan nominal diterima.
- [x] Ubah tab Donasi member menjadi riwayat milik sendiri; hilangkan daftar donatur lain dan agregat per donatur.
- [x] Tambahkan antrean dan detail verifikasi admin dengan catatan serta identitas/waktu pemeriksa.
- [x] Terapkan pembatasan RLS untuk select/insert/update serta akses bukti pembayaran.
- [x] Sediakan pengaturan admin untuk instruksi rekening dan QRIS resmi yang digunakan.
- [x] Tambahkan menu Pengaturan Donasi khusus admin untuk gambar QRIS dan informasi rekening/instruksi pembayaran; hanya admin dapat mengubah rekening tujuan, member hanya memiliki akses baca.
- [x] Simpan gambar QRIS pada bucket khusus dengan unggah/ganti/hapus admin-only; batasi ukuran dan tipe file gambar.
- [x] Pastikan hanya donasi terverifikasi dihitung ke total dana diterima.
- [x] Member dapat membuat laporan untuk dirinya sendiri; admin menjadi validator/verifikator dan dapat mencatat donasi tanpa member.

## Kriteria penerimaan

- Member A tidak dapat membaca donasi Member B melalui layar maupun query langsung ke Supabase.
- Member melihat daftar riwayatnya sendiri beserta metode dan status yang mudah dipahami.
- Laporan baru dan bukti unggahan tidak otomatis membuat status terverifikasi.
- Admin dapat memeriksa tiga metode pembayaran dan mencatat nominal yang benar-benar diterima.
- Hanya admin yang dapat menetapkan status terverifikasi.
- Perbedaan nominal dan penolakan memiliki alasan yang dapat ditelusuri.
- Total penerimaan hanya memasukkan donasi yang telah disahkan.
- Donasi anonim tidak membocorkan identitas atau jumlah kepada member.

## Keputusan MVP yang dipakai (silakan review)

1. Member membuat laporan donasi untuk dirinya sendiri; admin dapat mencatat donasi tanpa member untuk kebutuhan kas/anonim.
2. Bukti transfer/QRIS bersifat opsional; referensi transaksi juga dapat digunakan.
3. MVP memakai QRIS statis yang gambarnya dikelola admin; verifikasi tetap manual.
4. Donasi tanpa member hanya dapat dilihat admin.
