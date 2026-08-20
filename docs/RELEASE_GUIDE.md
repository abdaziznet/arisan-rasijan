# Panduan Rilis Aplikasi BANI RASIJAN

Dokumen ini menjelaskan langkah-langkah untuk membuat build rilis Android dan mendistribusikannya melalui Google Play Console.

## 1. Persiapan Keystore Signing

Aplikasi dikonfigurasi untuk memuat properti penandatanganan rilis dari file `android/key.properties`. File ini bersifat rahasia dan **tidak boleh dikomit** ke repositori Git (telah diabaikan di `.gitignore`).

### Langkah Membuat Keystore Baru (Jika Diperlukan)

Jika Anda perlu membuat keystore baru, jalankan perintah berikut di terminal:

```bash
keytool -genkey -v -keystore android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

Setelah itu, buat/perbarui file `android/key.properties` dengan detail berikut:

```properties
storePassword=<PASSWORD_KEYSTORE_ANDA>
keyPassword=<PASSWORD_KEY_ANDA>
keyAlias=key
storeFile=app/key.jks
```

## 2. Play App Signing

Saat mengunggah aplikasi pertama kali ke Google Play Console, Google Play secara default akan menggunakan **Play App Signing**.

1. Google Play akan membuat dan menyimpan kunci penandatanganan aplikasi utama secara aman di server Google.
2. Anda mengunggah aplikasi yang ditandatangani dengan kunci unggahan Anda (`key.jks` yang dibuat di atas).
3. Google Play memverifikasi kunci unggahan Anda, lalu menandatangani ulang APK/AAB dengan kunci penandatanganan aplikasi utama sebelum didistribusikan ke pengguna.

Pastikan Anda menyimpan file `key.jks` dan password penandatanganan dengan aman. Jika hilang, Anda harus menghubungi dukungan Google Play Console untuk mereset kunci unggahan.

## 3. Membuat Build Rilis Android (AAB)

Gunakan format **Android App Bundle (.aab)** untuk diunggah ke Google Play Console.

Jalankan perintah berikut di direktori root proyek:

```bash
flutter build appbundle --release
```

Hasil build akan berada di `build/app/outputs/bundle/release/app-release.aab`.

## 4. Distribusi Melalui Play Console

### Pengujian Internal (Internal Testing)

Cara tercepat untuk mendistribusikan aplikasi ke keluarga untuk diuji:

1. Masuk ke [Google Play Console](https://play.google.com/console/).
2. Pilih aplikasi **BANI RASIJAN** (atau buat aplikasi baru jika belum terdaftar).
3. Di menu sebelah kiri, masuk ke **Testing** > **Internal testing**.
4. Klik **Create new release**.
5. Unggah file `app-release.aab` yang dihasilkan dari langkah 3.
6. Masukkan detail rilis (release notes) singkat.
7. Klik **Save and publish**.
8. Tambahkan email penguji (keluarga) ke daftar **Testers** di tab penguji internal.
9. Bagikan tautan bergabung (join link) kepada keluarga Anda. Mereka dapat mengunduh aplikasi langsung dari Google Play Store pada perangkat Android mereka setelah mengeklik tautan tersebut.
