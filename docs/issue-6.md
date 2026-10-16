# Issue 6 — Bacaan Al-Qur'an untuk Agenda Yasin & Sholawat

**Status:** MVP diimplementasikan; verifikasi perangkat masih terbuka
**Sumber bacaan:** [EQuran.id API v2](https://equran.id/apidev/v2), bersumber dari Kementerian Agama RI
**Lokasi fitur:** Agenda Acara → Yasin & Sholawat; pintasan tersedia dari Beranda

## Ringkasan

Tambahkan pembaca Al-Qur'an yang membantu keluarga membaca Yasin bersama pada agenda rutin. Pengguna dapat membuka daftar surah, mencari, dan membaca teks Arab, latin, serta terjemahan Indonesia. Bacaan yang sudah dimuat disimpan di perangkat supaya tetap tersedia saat offline. Fitur menjadi modul kontekstual dan tidak menambah tab navigasi utama.

## Kesesuaian dengan aplikasi

- Aplikasi memakai Flutter, Riverpod, `SharedPreferences`, `AppRouter`, dan tema pada `lib/core/theme/`.
- Agenda acara sudah memiliki langkah `Yasin & Sholawat` dan menjadi titik masuk utama ke pembaca.
- Beranda dapat memberi akses cepat ke Surah Yasin tanpa mengubah navigasi `Beranda | Iuran | Arisan | Profil`.
- Data bacaan bersifat publik dan lokal; tidak disimpan ke Supabase atau dikaitkan dengan data anggota.
- Untuk pemakaian pertemuan, Surah Yasin (36) menjadi aksi utama; daftar 114 surah tetap tersedia.

## Cakupan rilis ini

### Fungsional

- [x] Daftar surah dengan nomor, nama Arab/latin, arti, jumlah ayat, dan tempat turun.
- [x] Pencarian lokal berdasarkan nama, arti, atau nomor.
- [x] Detail surah dengan teks Arab, transliterasi, dan terjemahan Indonesia.
- [x] Akses daftar surah dari agenda Yasin & Sholawat dan akses cepat Surah Yasin dari Beranda.
- [x] Cache lokal persisten untuk daftar dan surah yang pernah dibuka (cache-first, tanpa TTL pendek).
- [x] Pengaturan ukuran teks Arab dan tampil/sembunyikan latin/terjemahan yang disimpan lokal.
- [x] Simpan surah/ayat terakhir yang terlihat dan tandai/hapus bookmark ayat secara lokal.
- [x] Loading, error, coba lagi, hasil pencarian kosong, dan fallback cache offline.
- [x] Tolak nomor surah di luar rentang 1–114 sebelum request; parsing respons defensif.
- [x] Atribusi EQuran.id/Kementerian Agama pada halaman pembaca.

### Di luar cakupan

- Audio murottal, tafsir, mushaf per halaman, tajwid berwarna, akun/sinkronisasi cloud.
- Daftar bookmark dengan navigasi langsung ke ayat dan pemulihan posisi ayat persis saat membuka kembali (iterasi lanjutan).
- Mengubah atau mengoreksi teks sumber.
- Menambahkan tab Al-Qur'an di navigasi utama.

## UI/UX

- Ikuti Design Specification BANI RASIJAN: warna semantik, kartu putih, border halus, jarak 4px, tipografi aplikasi, dan kontrol sentuh minimal 44–48dp.
- Pada agenda, tampilkan tombol berlabel “Buka Bacaan Yasin” hanya pada langkah Yasin & Sholawat.
- Daftar surah dibuat sederhana dan mudah dipakai lintas usia; Surah Yasin diberi penanda untuk membantu acara.
- Ayat memakai arah RTL dan rata kanan; Arab menjadi hierarki utama, diikuti latin dan terjemahan.
- Hindari animasi dekoratif; hormati `MediaQuery.disableAnimations`.
- Font Arab menggunakan fallback sistem Flutter untuk fase ini. Pengujian visual lintas perangkat diperlukan sebelum rilis karena aset font Uthmani khusus belum tersedia di repo.

## Arsitektur

`lib/features/quran/` mengisolasi model, sumber API/cache, repository, provider Riverpod, dan layar. HTTP memakai `dart:io` `HttpClient` (tanpa dependensi baru). Cache dan preferensi menggunakan `SharedPreferences`. API v2 memakai wrapper `{code, message, data}`; parser menerima wrapper maupun data langsung untuk ketahanan.

## Acceptance checklist

- [x] Daftar 114 surah tampil, dapat dicari, dan menampilkan keadaan loading/error/kosong.
- [x] Surah dapat dibuka dengan teks Arab, latin, dan terjemahan.
- [x] Surah yang pernah dibuka tersedia dari cache offline.
- [x] Kontrol font Arab dan visibilitas latin/terjemahan tersimpan.
- [x] Posisi bacaan terakhir dicatat lokal dan bookmark ayat dapat ditandai/dihapus.
- [ ] Melanjutkan bacaan tepat di ayat terakhir dan membuka ayat dari daftar bookmark.
- [x] Pembaca dapat dibuka dari agenda Yasin & Sholawat; Beranda menyediakan pintasan Yasin.
- [x] Sumber bacaan disebutkan di UI.
- [ ] Validasi visual teks Arab/harakat pada perangkat Android dan iOS nyata.

## Verifikasi

- Test terfokus Al-Qur'an dan Agenda: lulus (10 test).
- Analyzer untuk semua file issue 6: bersih. Analyzer seluruh repo masih melaporkan 17 temuan lama di file lain.
- Test Beranda dijalankan; satu ekspektasi lama gagal karena mengharapkan `Rp125.000` sementara fixture menetapkan `contributionAmount: 100000`. Test Beranda lain lulus.
- `dart format` dijalankan pada berkas Dart yang disentuh.
- Manual: Surah Al-Fatihah, Surah Yasin, surah panjang, mode pesawat setelah cache, teks besar, serta reduced motion.
- Pemeriksaan visual pada perangkat Android/iOS nyata masih terbuka, terutama untuk bentuk harakat karena font Uthmani belum dibundel.

## Referensi

- `specification/PRD.md` — agenda Yasin & Sholawat dan kebutuhan offline.
- `design/DESIGN.md` — navigasi, event agenda, aksesibilitas, dan tema.
- [Dokumentasi resmi EQuran.id API v2](https://equran.id/apidev/v2).
