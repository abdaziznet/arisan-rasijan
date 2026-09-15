# Mockup UX Flow — Profil + Maps

## 1. Flow Utama: Edit Profil Rumah

### Screen A — Profil User
- Header: "Profil Saya"
- Foto profil
- Nama lengkap
- Nomor telepon
- Email / akun
- Card: "Alamat Rumah"
  - Alamat lengkap
  - Kota / Kecamatan
  - Tombol: "Ambil Lokasi Saat Ini"
  - Tombol: "Simpan Perubahan"

### Screen B — Form Alamat Rumah
- Judul: "Alamat Rumah"
- Field:
  - Nama Jalan / RT / RW
  - Kelurahan / Kecamatan
  - Kota / Kabupaten
  - Kode Pos (opsional)
  - Latitude
  - Longitude
- Action:
  - "Ambil Lokasi Saat Ini" (menggunakan permission)
  - "Reset"
  - "Simpan"

### State: Izin Lokasi Diberikan
- Aplikasi menampilkan bottom sheet kecil:
  - "Akses lokasi diperlukan untuk mengambil koordinat rumah Anda."
  - Buttons: "Izinkan" / "Masukkan Manual"
- Setelah diizinkan, sistem otomatis mengambil current location
- field latitude dan longitude terisi otomatis

### State: Izin Lokasi Ditolak
- Aplikasi tetap memberi opsi manual
- Tampilkan pesan:
  - "Izin lokasi tidak diberikan. Anda tetap bisa mengisi alamat rumah secara manual."
- User tetap bisa menyimpan alamat tanpa koordinat

---

## 2. Flow Utama: Home Screen + Direction

### Screen C — Home Screen
- Greeting: "Assalamualaikum, Bapak/Ibu"
- Card utama: "Arisan Periode #3"
  - Tuan rumah: "Bapak Arif"
  - Tanggal: "Sabtu, 12 Oktober 2026"
  - Alamat: "Jl. Mawar No. 18, Bandung"
  - Icon direction di sisi kanan card
  - Status: "Lokasi tersedia"

### Screen D — Tap Tombol Direction
- Aplikasi membuka Google Maps link:
  - arah dari current location user ke destination rumah tuan rumah
- Jika device tidak punya Google Maps:
  - fallback ke browser `maps.google.com`

---

## 3. Wireframe Ringkas (ASCII)

### Profil Form
+--------------------------------------------------------+
| Profil Saya                                           |
| [Avatar] Nama Lengkap                                  |
| No HP: 0812xxxxxxx                                     |
| Email: user@mail.com                                   |
|--------------------------------------------------------|
| Alamat Rumah                                           |
| Jalan / RT / RW                                       |
| Kelurahan / Kecamatan                                  |
| Kota / Kabupaten                                       |
| Latitude: -6.900000                                    |
| Longitude: 107.600000                                  |
| [Ambil Lokasi Saat Ini] [Simpan]                       |
+--------------------------------------------------------+

### Home Screen
+--------------------------------------------------------+
| Assalamualaikum, Aisyah                                 |
|--------------------------------------------------------|
| Arisan Periode #3                                      |
| Tuan Rumah: Bapak Arif                                  |
| 12 Oktober 2026                                        |
| Jl. Mawar No. 18, Bandung                               |
| [icon direction]  [lihat detail]                       |
+--------------------------------------------------------+

---

## 4. UX Notes

- Desain harus tetap minimal, familier, dan tidak terlalu berat visualnya
- Arah (direction) harus ditempatkan dekat dengan informasi rumah tuan rumah agar mudah ditemukan
- Tombol direction menggunakan ikon pin/arrow yang jelas, bukan teks panjang
- Jika lokasi tidak tersedia, tombol direction dinonaktifkan dengan style redup
- Hasil ambil lokasi harus tampak jelas dan bisa diedit ulang kapan saja

---

## 5. Acceptance Criteria UX

- User dapat membuka form alamat rumah dari profil
- User dapat mengambil koordinat dari perangkat via permission
- Data latitude/longitude terbaru terlihat setelah disimpan
- Home screen menampilkan rumah tuan rumah dan tombol arah secara jelas
- Jika koordinat tidak valid, sistem tetap menampilkan alamat teks tanpa crash
