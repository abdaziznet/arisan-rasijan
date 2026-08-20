# Pertanyaan yang Belum Terjawab

## OQ-001 — Penyimpanan kode undangan

Sumber:
PRD.md, ARCHITECTURE.md, DATABASE_SCHEMA.md

Konflik:
PRD mengharuskan adanya kode undangan untuk anggota baru dan arsitektur mengharuskan kode tersebut di-hash, memiliki masa berlaku, serta dapat dicabut. DATABASE_SCHEMA.md belum mendefinisikan entitas, kolom, atau kebijakan untuk menyimpan kode undangan.

Dampak:
Alur pendaftaran melalui undangan belum dapat diimplementasikan berdasarkan skema yang terdokumentasi tanpa menambahkan struktur database yang belum didokumentasikan.

Rekomendasi:
Tentukan model data dan kebijakan RLS untuk kode undangan, atau secara eksplisit setujui penggunaan tabel khusus atau kontrak Edge Function.

Status:
Resolved

## OQ-002 — Visibilitas voting gathering

Sumber:
DATABASE_SCHEMA.md, DESIGN.md

Konflik:
DATABASE_SCHEMA.md menyerahkan keputusan mengenai apakah anggota dapat melihat pilihan vote individu kepada kesepakatan keluarga. DESIGN.md merekomendasikan voting privat secara bawaan, dengan hanya menampilkan jumlah total suara.

Dampak:
Tampilan hasil dan progres voting membutuhkan perilaku privasi yang telah disepakati.

Rekomendasi:
Konfirmasikan voting privat sebagai perilaku bawaan MVP, dengan total suara terlihat oleh anggota tetapi pilihan setiap individu disembunyikan.

Status:
Resolved

## OQ-003 — Pilihan manajemen state Flutter

Sumber:
ARCHITECTURE.md

Konflik:
Arsitektur menyarankan untuk mempertahankan pola manajemen state dari proyek sebelumnya, tetapi repositori ini adalah proyek baru dan belum memiliki pola yang digunakan.

Dampak:
Aplikasi membutuhkan satu implementasi provider/controller yang konsisten untuk state asynchronous dan realtime.

Rekomendasi:
Gunakan Riverpod dengan controller yang dikelompokkan per fitur, kecuali terdapat konvensi proyek keluarga yang sudah digunakan sebelumnya.

Status:
Resolved

## OQ-004 — Konfigurasi environment Supabase

Sumber:
ARCHITECTURE.md

Konflik:
Arsitektur mengharuskan penggunaan Supabase Auth, tetapi proyek belum memiliki URL proyek Supabase, anon key, redirect URI, atau konvensi file environment.

Dampak:
Email Magic Link/OTP belum dapat dihubungkan maupun diverifikasi pada perangkat seluler.

Rekomendasi:
Sediakan detail koneksi proyek Supabase dan skema deep link Android/iOS yang diizinkan, kemudian tambahkan konfigurasi environment yang tidak dikomit ke repository.

Evidence:
sudah ada di file .env

Status:
Resolved
