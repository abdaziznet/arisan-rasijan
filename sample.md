buatkan saya file issue.md untuk melanjutkan pengembangan aplikasi ini dimulai dari screen login dengan membaca file [PRD.md](d:/05-Labs/01-flutter/arisan_rasijan/specification/PRD.md) , [ARCHITECTURE.md](d:/05-Labs/01-flutter/arisan_rasijan/specification/ARCHITECTURE.md) [DATABASE_SCHEMA.md](d:/05-Labs/01-flutter/arisan_rasijan/specification/DATABASE_SCHEMA.md)  untuk design bisa membaca file [DESIGN.md](d:/05-Labs/01-flutter/arisan_rasijan/design/DESIGN.md) [COMPONENTS.md](d:/05-Labs/01-flutter/arisan_rasijan/design/COMPONENTS.md) [DESIGN_TOKENS.md](d:/05-Labs/01-flutter/arisan_rasijan/design/DESIGN_TOKENS.md) [UI_SCREENS.md](d:/05-Labs/01-flutter/arisan_rasijan/design/UI_SCREENS.md) 
dan buatkan juga checklist di dalam issue.md agar jika feature sudah di implementasi bisa kembali membaca checklist dulu sebelum melanjutkan feature yang mau di buat.

Gunakan skill yang ada pada project ini untuk implementasinya

simpan file issue.md ke dalam folder @docs/



buatkan saya file issue-5.md untuk melanjutkan pengembangan aplikasi ini
spesifikasinya sebgai berikut:
1. pada form login saat ini tambahkan feature biometric authentication jika device sudah support biometric jika belum tidak perlu.
2. Aktivasi opsional: setelah login berhasil, tawarkan "Aktifkan kunci sidik jari/Face ID" dan simpan pilihannya.
3. Kunci saat app dibuka dari cold start dan saat kembali dari background lebih dari N menit (misalnya 1 sampai 5 menit) bisa di atur pada configurasi
4. Fallback ketika biometrik gagal, tidak tersedia, atau dibatalkan: login ulang via google auth yang saat ini.
5. Batas percobaan gagal, lalu paksa login ulang.
6. Menu pengaturan untuk mematikan fitur.
7. Biometrik bukan bukti identitas ke server. Keamanan data tetap bergantung pada RLS dan JWT Supabase, bukan pada kunci layar ini.
8. Tangani kasus biometrik perangkat berubah (sidik jari baru ditambahkan): minta login ulang kalau memakai opsi pengikatan token.
9. gunakan skill yang ada pada project ini untuk mendesign ui/ux nya.
10. gunakan skill animation pada project ini agar terlihat lebih modern.
11. baca kembali file DESIGN.md untuk warna yang harus di terapkan agar konsisten.
12. lakukan test terlebih  dahulu , pastikan tidak ada fungsi yang berdampak pada penambahan feature ini
13. pastikan gunakan dependency yang cocok dan support dengan device modern.