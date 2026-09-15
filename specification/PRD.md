# Product Requirements Document (PRD)
## Aplikasi Arisan Keluarga

**Versi:** 1.0
**Status:** Draft
**Platform:** Mobile (Android & iOS) — Flutter

---

## 1. Latar Belakang

Keluarga mengadakan arisan rutin setiap **2 bulan sekali** dengan format sebagai berikut:

1. Kumpul bersama di rumah tuan rumah periode berjalan
2. Membaca Yasin dan Sholawat bersama
3. Donasi (**opsional** — kadang ada, kadang tidak)
4. Makan bersama, disediakan oleh tuan rumah
5. Kocokan arisan untuk menentukan pemenang periode berikutnya
6. Uang yang terkumpul diserahkan kepada pemenang
7. Pemenang otomatis menjadi **tuan rumah** untuk periode arisan selanjutnya
8. Foto bersama
9. Salam penutup, anggota kembali ke rumah masing-masing

Saat ini proses pencatatan iuran, penentuan tuan rumah, dan histori kocokan masih dilakukan secara manual, sehingga rawan miss dan sulit ditelusuri riwayatnya. Aplikasi ini dibuat untuk mendigitalkan proses tersebut agar lebih transparan, terdokumentasi, dan mudah diakses oleh seluruh anggota keluarga.

---

## 2. Tujuan Produk

- Menyediakan sistem kocokan digital yang transparan dan tidak bisa dimanipulasi
- Mempermudah tracking iuran & donasi tiap periode
- Mendokumentasikan histori arisan (pemenang, tuan rumah, foto) secara terpusat
- Mengingatkan anggota tentang jadwal & lokasi arisan berikutnya
- Menjadi arsip keluarga jangka panjang (siapa saja yang pernah menang/jadi tuan rumah)

---

## 3. Target Pengguna

Aplikasi ini bersifat **privat**, hanya digunakan oleh anggota satu keluarga besar yang tergabung dalam kelompok arisan tersebut. Estimasi jumlah pengguna: skala kecil (belasan–puluhan orang).

### Role Pengguna

| Role | Deskripsi | Hak Akses |
|---|---|---|
| **Admin/Bendahara** | Biasanya 1–2 orang yang mengelola kas & acara | Kelola anggota, catat iuran, jalankan kocokan, kelola jadwal |
| **Anggota** | Seluruh anggota keluarga yang ikut arisan | Lihat jadwal, riwayat, saldo, foto; input konfirmasi pembayaran |

---

## 4. Konsep Inti (Core Logic)

- **Siklus arisan:** 1 periode = 2 bulan
- **Tuan rumah periode berjalan** = pemenang kocokan periode sebelumnya
- **Kocokan** dilakukan di akhir acara, hasilnya menentukan:
  - Siapa yang menerima uang terkumpul periode ini
  - Siapa yang menjadi tuan rumah periode berikutnya
- **Aturan pengulangan pemenang**: perlu disepakati keluarga — apakah anggota yang sudah pernah menang di-*exclude* dari kocokan berikutnya sampai semua anggota kebagian, atau tetap boleh menang lagi (sistem harus bisa dikonfigurasi sesuai kesepakatan keluarga)

---

## 5. Fitur

### 5.1 Must Have (MVP)

**A. Manajemen Anggota**
- CRUD data anggota (nama, foto, no HP, email, alamat)
- Role admin & anggota
- Invite code / undangan untuk anggota baru bergabung

**B. Autentikasi**
- Login via **Email Magic Link/OTP** (tanpa password)
- Session tersimpan otomatis di app

**C. Jadwal & Periode Arisan**
- Info periode arisan berjalan: tanggal, tuan rumah, alamat, lokasi (maps)
- Auto-generate periode berikutnya (interval 2 bulan)
- Reminder H-7 dan H-1 (push notification)

**D. Sistem Kocokan (Core Feature)**
- Undian digital dengan animasi visual saat acara berlangsung
- Opsi exclude anggota yang sudah pernah menang (configurable)
- Hasil otomatis tersimpan sebagai histori
- Pemenang otomatis di-set sebagai tuan rumah periode berikutnya

**E. Iuran & Keuangan**
- Input & tracking status pembayaran iuran per anggota per periode
- Modul donasi terpisah (opsional per periode)
- Total kas terkumpul otomatis terhitung
- Riwayat keuangan per periode & keseluruhan

**F. Agenda Acara**
- Checklist rundown: Kumpul → Yasin & Sholawat → Makan → Kocokan → Serah Terima Uang → Foto Bersama → Penutupan
- Bisa dicentang admin secara real-time saat acara berlangsung

**G. Histori & Dokumentasi**
- Riwayat lengkap pemenang & tuan rumah per periode
- Galeri foto per sesi arisan
- Statistik sederhana (misal: jumlah periode, siapa yang belum pernah jadi tuan rumah)

**H. Kas Bersama & Event Gathering**
- Sebagian nominal dari iuran tiap anggota **otomatis dipotong** dan dialokasikan ke **kas bersama khusus gathering** (terpisah dari uang yang diserahkan ke pemenang kocokan)
- Persentase/nominal potongan bisa diatur oleh admin (misal: 10% dari tiap iuran masuk ke kas gathering)
- **Total kas gathering saat ini** ditampilkan secara real-time kepada seluruh anggota (transparansi dana bersama)
- Ketika kas dianggap cukup, admin dapat **menginisiasi Event Gathering** baru
- Admin membuat **voting tujuan gathering**: admin memasukkan beberapa opsi tujuan (misal: "Wisata ke Bandung", "Makan bersama di Restoran X", dll)
- Setiap anggota memberikan **1 suara** untuk opsi pilihannya melalui aplikasi
- **Voting otomatis ditutup** ketika seluruh anggota aktif sudah memberikan suara
- Opsi dengan suara terbanyak menjadi **tujuan gathering terpilih**
- Setelah voting selesai, admin dapat menetapkan tanggal & mencatat nominal kas yang dipakai untuk event tersebut, sehingga saldo kas gathering otomatis berkurang
- **Pengaturan visibilitas voting**: admin memiliki toggle konfigurasi untuk menentukan apakah pilihan suara tiap anggota (siapa memilih opsi apa, tally sementara) bisa dilihat oleh seluruh anggota, atau hanya admin yang bisa melihat detailnya selama proses berlangsung — anggota tetap bisa melihat opsi yang tersedia dan status voting (berapa yang sudah/belum vote) terlepas dari pengaturan ini, yang dibatasi hanya rincian pilihan per anggota

### 5.2 Nice to Have (Fase 2)

- Export laporan keuangan ke PDF/Excel
- Widget home screen: "Arisan berikutnya di rumah siapa & kapan"
- Mode offline dengan sync otomatis saat online kembali
- Notifikasi grup/pengumuman dari admin
- Backup/restore data manual

### 5.3 Out of Scope

- Tidak dibuat sebagai aplikasi multi-tenant/publik (khusus 1 grup keluarga)
- Tidak ada fitur chat internal (memanfaatkan grup WhatsApp keluarga yang sudah ada)
- Tidak menangani pembayaran online/payment gateway di versi awal (pencatatan manual status bayar)

### 5.4 Lokasi & Navigasi Rumah (terintegrasi ke MVP)

Untuk mendukung koordinasi arisan yang lebih praktis, aplikasi perlu menyimpan data lokasi rumah anggota dan rumah tuan rumah secara terstruktur. Fitur ini tidak menggantikan fungsi utama arisan, tetapi menjadi pendukung yang penting agar anggota lebih mudah mengecek jadwal, arah keberangkatan, dan lokasi acara.

**Fitur utama**
- Profil anggota memiliki field alamat rumah, kota, latitude, longitude, dan last updated
- User dapat mengambil lokasi saat ini dari perangkat untuk mengisi koordinat rumah
- Home screen menampilkan info lokasi rumah tuan rumah periode aktif
- Tombol direction memandu user ke Google Maps secara cepat
- Jika lokasi tidak tersedia, sistem tetap menampilkan alamat teks dan fallback manual

**Aturan bisnis**
- Data lokasi bersifat keluarga/private dan hanya digunakan untuk kebutuhan arisan
- User hanya dapat mengubah data lokasi dirinya sendiri, kecuali admin mendapat otorisasi khusus
- Tombol arah hanya aktif jika koordinat tujuan valid
- Jika izin lokasi ditolak, user tetap bisa mengisi alamat secara manual

**Manfaat**
- Mengurangi kebingungan saat mencari lokasi rumah tuan rumah
- Menyederhanakan koordinasi sebelum acara dimulai
- Membuat profil keluarga lebih lengkap dan siap digunakan untuk kebutuhan event

---

## 6. Alur Pengguna (User Flow)

### Alur Utama: Siklus 1 Periode Arisan

1. Aplikasi menampilkan info periode berjalan (tuan rumah, tanggal, lokasi)
2. Anggota melakukan pembayaran iuran secara manual (tunai/transfer), lalu admin mencatat status "sudah bayar" di app
3. (Opsional) Anggota memberi donasi, dicatat terpisah oleh admin
4. Reminder otomatis terkirim H-7 dan H-1
5. Saat hari-H, admin membuka fitur agenda & mencentang tiap tahap acara berjalan
6. Di akhir acara, admin membuka fitur kocokan → menjalankan undian di depan anggota
7. Sistem menampilkan pemenang → otomatis tercatat sebagai penerima uang & tuan rumah periode berikutnya
8. Admin upload foto-foto acara ke galeri
9. Periode baru otomatis ter-generate dengan tuan rumah & tanggal baru (+2 bulan)
10. Sebagian dari iuran periode ini otomatis dialokasikan ke kas gathering, saldo kas ter-update

### Alur Fitur Event Gathering & Voting

1. Anggota dapat memantau **total kas gathering** kapan saja dari halaman utama app
2. Ketika saldo kas dirasa cukup, admin membuat **Event Gathering baru** beserta beberapa **opsi tujuan**
3. Aplikasi mengirim notifikasi ke seluruh anggota bahwa voting telah dibuka
4. Tiap anggota membuka app dan memilih 1 opsi tujuan (1 orang = 1 suara, tidak bisa diubah setelah submit)
5. Sistem memantau jumlah suara masuk; begitu **seluruh anggota aktif sudah vote**, voting otomatis ditutup
6. Sistem menampilkan opsi pemenang (suara terbanyak) ke semua anggota
7. Admin menetapkan tanggal pelaksanaan & mencatat nominal kas yang terpakai untuk event tersebut
8. Saldo kas gathering otomatis berkurang sesuai nominal yang dipakai

### Alur Fitur Lokasi & Navigasi

1. Anggota membuka halaman profil dan memilih menu "Alamat Rumah"
2. Sistem menampilkan field alamat lengkap, kota, latitude, longitude, dan tombol "Ambil Lokasi Saat Ini"
3. Jika user memberi izin lokasi, aplikasi menyimpan koordinat otomatis dari perangkat
4. Jika user menolak izin, sistem tetap memberi opsi input manual untuk alamat dan koordinat yang bisa diisi nanti
5. Pada home screen, card periode aktif menampilkan alamat rumah tuan rumah dan tombol direction
6. User tap tombol arah, aplikasi membuka Google Maps menuju lokasi tujuan
7. Jika Google Maps tidak terpasang, aplikasi membuka browser sebagai fallback

---

## 7. Roadmap Implementasi per Modul

### Modul 1: Profil & Data Alamat
- Tujuan: menyimpan lokasi rumah anggota secara terstruktur dan siap dipakai di home screen
- Scope:
  - menambahkan field `address`, `city`, `latitude`, `longitude`, `updated_at` di `profiles`
  - form edit profil dengan section `Alamat Rumah`
  - tombol `Ambil Lokasi Saat Ini`
  - validasi koordinat dan fallback manual
- Deliverable:
  - profil bisa diisi dan diperbarui tanpa error
  - koordinat tersimpan sesuai device user

### Modul 2: Home Screen & Informasi Tuan Rumah
- Tujuan: menampilkan lokasi arisan aktif dengan jelas di halaman utama
- Scope:
  - card periode berjalan dengan alamat dan nama tuan rumah
  - tombol arah (icon direction) yang terlihat jelas
  - status jika lokasi tidak tersedia atau belum diisi
- Deliverable:
  - anggota langsung melihat informasi lokasi acara dari home screen

### Modul 3: Integrasi Maps & Navigasi
- Tujuan: membuka Google Maps langsung dengan arah dari lokasi user ke tujuan
- Scope:
  - deep link ke `google.navigation:q=...` atau `maps.google.com` fallback
  - pengecekan ketersediaan aplikasi Google Maps
  - pesan error jika koordinat tujuan invalid
- Deliverable:
  - satu tap membuka navigasi ke rumah tuan rumah

### Modul 4: Permission & Privasi
- Tujuan: menjaga keamanan data lokasi keluarga tanpa mengganggu pengalaman user
- Scope:
  - minta izin lokasi hanya saat user memilih `Ambil Lokasi Saat Ini`
  - tampilkan penjelasan penggunaan lokasi dengan bahasa yang jelas
  - bila izin ditolak, tetap lanjutkan dengan mode manual
  - data hanya diakses untuk kebutuhan arisan keluarga
- Deliverable:
  - permission flow aman, jelas, bisa dipahami oleh user dengan berbagai tingkat teknis

### Modul 5: Observability & QA
- Tujuan: memastikan fitur lokasinya stabil pada perangkat nyata
- Scope:
  - test validasi latitude/longitude
  - test fallback saat maps tidak tersedia
  - test kondisi izin lokasi ditolak
  - test card home pada perangkat kecil / layar sempit
- Deliverable:
  - release safe untuk internal testing

---

## 8. Kebutuhan Non-Fungsional

- **Privasi & Keamanan**: data keuangan keluarga harus terproteksi — hanya anggota grup yang bisa mengakses (Row Level Security)
- **Ketersediaan**: harus tetap bisa dibuka meski sinyal internet lemah di lokasi acara (idealnya ada caching data periode berjalan)
- **Kemudahan penggunaan**: UI sederhana, mengingat pengguna lintas usia (termasuk anggota keluarga yang lebih senior)
- **Transparansi**: proses kocokan harus terlihat adil & tidak bisa direkayasa

---

## 9. Metrik Keberhasilan

- Seluruh anggota aktif menggunakan app untuk cek jadwal & histori
- Tidak ada lagi selisih pencatatan iuran/kas
- Proses kocokan sepenuhnya berpindah dari manual (kertas/undian fisik) ke digital
- Histori arisan tersimpan rapi minimal untuk 5+ periode ke depan

---

## 10. Rencana Rilis

- **Fase 1 (MVP)**: fitur must-have di atas, dirilis via Google Play Console — **Internal Testing / Closed Testing** (bukan publik, karena app privat keluarga)
- **Fase 2**: fitur nice-to-have berdasarkan feedback pemakaian riil

---

## 11. Referensi Dokumen Terkait

- Struktur database: lihat `DATABASE_SCHEMA.md`
- Arsitektur teknis & stack: lihat `ARCHITECTURE.md`