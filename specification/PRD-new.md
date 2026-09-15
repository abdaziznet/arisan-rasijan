# PRD New — Lokasi & Navigasi Arisan

## 1. Latar Belakang

Fitur ini merupakan pengembangan lanjutan dari PRD utama untuk meningkatkan pengalaman penggunaan aplikasi dalam konteks keluarga arisan. Saat ini, informasi lokasi arisan biasanya hanya berupa alamat teks dan sering kali mengharuskan anggota mengingat atau membuka aplikasi lain untuk mencari lokasi rumah tuan rumah.

Untuk memudahkan koordinasi, aplikasi perlu menyediakan:
- data alamat rumah anggota yang bisa disimpan di profil
- akses lokasi saat ini (current location) menggunakan perangkat
- pemetaan lokasi rumah tuan rumah
- tombol navigasi cepat ke Google Maps untuk arah perjalanan

Tujuan utamanya adalah mempercepat orientasi anggota sebelum datang ke acara, sekaligus menjaga konsistensi data lokasi di dalam aplikasi.

---

## 2. Tujuan Fitur

- Menyediakan data lokasi rumah anggota secara terstruktur di profil
- Memungkinkan sistem mengambil latitude/longitude dari perangkat user
- Menyimpan dan menampilkan lokasi rumah tuan rumah secara lebih akurat
- Memudahkan anggota mengikuti arah ke lokasi arisan melalui Google Maps
- Mempercepat proses check-in dan koordinasi acara keluarga

---

## 3. User Story

### 3.1 Anggota
- Saya ingin mengisi alamat rumah saya di profil agar data lokasi keluarga lebih rapi.
- Saya ingin aplikasi menyalin latitude/longitude dari lokasi saya saat ini agar tidak salah input.
- Saya ingin menekan tombol arah langsung ke Google Maps agar tidak perlu membuka aplikasi lain.
- Saya ingin melihat lokasi rumah tuan rumah periode berjalan dari home screen.

### 3.2 Admin / Bendahara
- Saya ingin memastikan lokasi rumah tuan rumah di periode aktif jelas dan mudah diakses oleh anggota.
- Saya ingin lokasi per rumah bisa diverifikasi agar tidak terjadi kesalahan koordinat.
- Saya ingin tetap mengontrol data rumah yang boleh ditampilkan ke anggota.

---

## 4. Scope Fitur

### In Scope
- Pengaturan alamat rumah pada profil user
- Pengambilan latitude & longitude dari perangkat user
- Validasi alamat rumah dan koordinat lokasi
- Tampilkan lokasi rumah tuan rumah pada halaman utama arisan
- Tombol navigasi cepat ke Google Maps
- Penggunaan lokasi hanya untuk kebutuhan arisan keluarga

### Out of Scope
- Peta interaktif penuh di dalam aplikasi
- Integrasi dengan layanan navigasi lain selain Google Maps
- Fitur geofencing atau reminder otomatis berdasarkan lokasi user
- Menampilkan titik lokasi pribadi yang sensitif di luar konteks keluarga

---

## 5. Alur Pengguna

### 5.1 Menyimpan Lokasi Rumah di Profil
1. Anggota membuka profil
2. Pilih menu "Alamat Rumah"
3. Sistem menampilkan field:
   - alamat lengkap
   - kota / kecamatan
   - latitude
   - longitude
   - tombol "Ambil Lokasi Saat Ini"
4. User menekan tombol lokasi saat ini
5. Sistem meminta izin lokasi jika belum diberikan
6. Aplikasi mengambil koordinat dari perangkat
7. Data disimpan ke profil user
8. User bisa meninjau dan memperbarui data kapan saja

### 5.2 Melihat Lokasi Arisan di Home Screen
1. User masuk ke home screen
2. Menampilkan card periode aktif / rumah tuan rumah
3. Jika lokasi tersedia, sistem menampilkan alamat dan tombol arah
4. User menekan ikon direction
5. Aplikasi membuka Google Maps dengan arah dari lokasi device saat ini ke alamat tuan rumah

### 5.3 Navigasi ke Google Maps
1. User menekan tombol arah pada card arisan
2. Sistem mengecek apakah perangkat memiliki Google Maps yang terpasang
3. Jika tersedia, buka Google Maps dengan URL direction dari current location ke destination
4. Jika tidak tersedia, tampilkan fallback: buka browser dengan URL maps.google.com

---

## 6. Functional Requirements

### 6.1 Profil User
- Anggota dapat mengisi atau memperbarui alamat rumah
- Sistem menyimpan data alamat lengkap, kota, dan kode pos bila tersedia
- Sistem menyimpan latitude dan longitude sebagai titik lokasi rumah
- Sistem menyediakan tombol "Ambil Lokasi Saat Ini"

### 6.2 Lokasi Saat Ini
- Aplikasi meminta izin akses lokasi saat runtime
- Jika izin diberikan, aplikasi mengisi koordinat dari perangkat
- Jika izin ditolak, user tetap dapat mengisi alamat manual
- Data koordinat harus disimpan sebagai float atau decimal

### 6.3 Home Screen / Arisan Card
- Home screen menampilkan info rumah tuan rumah aktif
- Jika lokasi rumah tersedia, muncul tombol arah
- Tombol arah harus jelas dan mudah diidentifikasi dengan icon direction
- Saat diklik, aplikasi membuka Google Maps dengan tujuan alamat rumah tuan rumah

### 6.4 Maps Integration
- Integrasi tidak harus membangun peta custom di dalam app
- Fitur fokus pada navigasi dan orientasi lokasi
- Penggunaan Google Maps dilakukan melalui deep link / URL external intent

---

## 7. Data Model (Usulan)

### Profil User
- id
- full_name
- address
- city
- latitude
- longitude
- is_active
- updated_at

### Periode Arisan
- id
- period_number
- event_date
- host_id
- host_address
- host_latitude
- host_longitude
- status

### Catatan
- latitude dan longitude bisa diambil dari profil host atau diisi manual saat periode dibuat
- data lokasi tidak boleh tampil terlalu detail di layar umum kecuali sudah dibutuhkan di konteks arisan

---

## 8. Business Rules

- Lokasi rumah adalah data penting untuk koordinasi arisan, tetapi tetap bersifat privat dalam konteks keluarga
- User dapat mengedit alamat rumah sendiri, kecuali admin memiliki otorisasi khusus untuk update data anggota tertentu
- Jika latitude/longitude tidak ada, sistem tetap menampilkan alamat teks dengan fallback tanpa navigasi
- Tombol arah hanya aktif jika lokasi tujuan valid
- Sistem tidak boleh menampilkan location pin publik ke user yang tidak berhak melihat data tersebut

---

## 9. Non-Functional Requirements

### 9.1 Privasi
- Data lokasi rumah hanya digunakan untuk kebutuhan arisan keluarga dan navigasi
- Tidak boleh dipublikasikan ke khalayak umum
- Akses terhadap lokasi pribadi harus dibatasi sesuai role user

### 9.2 UX
- Proses pengambilan lokasi harus cepat dan jelas
- Kalau izin lokasi ditolak, UI harus menjelaskan bagaimana user tetap bisa mengisi alamat manual
- Tombol navigasi harus mudah ditemukan pada home screen

### 9.3 Reliability
- Jika Google Maps tidak tersedia, aplikasi harus tetap memberi alternatif via browser
- Jika koordinat tidak valid, sistem harus menampilkan pesan error yang ramah

---

## 10. User Experience Proposal

### Home Screen
- Card arisan aktif menampilkan:
  - tanggal
  - tuan rumah
  - alamat
  - tombol direction

### Profil Setting
- Section "Lokasi Rumah"
  - alamat lengkap
  - tombol ambil lokasi saat ini
  - preview lokasi di peta mini (opsional)

### Flow Icon Direction
- Tombol icon direction di sebelah card arisan
- Saat user tap, aplikasi membuka Google Maps langsung ke tujuan rumah tuan rumah

---

## 11. Acceptance Criteria

### AC-1: Pengaturan Alamat Rumah
- User dapat membuka halaman profil dan mengisi alamat rumah
- User dapat mengambil koordinat dari device
- Data tersimpan ke profil user

### AC-2: Lokasi Tuan Rumah
- Home screen menampilkan info lokasi rumah tuan rumah periode aktif
- Jika alamat valid, tombol direction muncul

### AC-3: Navigasi
- Klik tombol direction membuka Google Maps ke alamat tujuan
- Jika tidak ada Google Maps, fallback browser terbuka

### AC-4: Error Handling
- Jika lokasi tidak tersedia, app tidak crash
- UI menampilkan pesan yang jelas dan memberi opsi input manual

---

## 12. Prioritas Pengembangan

### MVP
- Profil alamat rumah
- Ambil lokasi saat ini
- Simpan latitude & longitude
- Tombol direction di home screen
- Integrasi ke Google Maps

### Phase 2
- Peta mini interaktif di dalam aplikasi
- Route preview
- Marker lokasi anggota rumah dalam satu keluarga
- Notifikasi lokasi / reminder saat akan berangkat

---

## 13. Kesimpulan

Fitur lokasi & navigasi ini sangat cocok untuk meningkatkan pengalaman penggunaan aplikasi keluarga arisan karena mengubah data alamat statis menjadi pengalaman yang praktis dan berguna. Dengan kemampuan membuka arah ke rumah tuan rumah melalui Google Maps, anggota tidak perlu mengandalkan ingatan atau mencari alamat secara manual.

Ini juga memperkuat prinsip utama PRD: transparansi, kemudahan penggunaan, dan koordinasi yang lebih rapi dalam menyelenggarakan arisan keluarga.
