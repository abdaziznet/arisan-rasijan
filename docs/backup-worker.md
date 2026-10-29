# PRD — Worker Backup Supabase di VM Ubuntu

| | |
|---|---|
| Versi | 1.2 (penyimpanan lokal di VM, restore otomatis ke Docker Postgres + MinIO) |
| Tanggal | 14 Oktober 2026 |
| Target | VM Ubuntu (LTS) sebagai worker backup |
| Dokumen pasangan | `backup.md` (aplikasi Flutter + backend Supabase: tabel, RLS, Edge Function, jadwal) |

---

## 1. Ringkasan

Worker adalah skrip bash di VM Ubuntu yang **menarik (poll) job backup dari tabel `backup_jobs` di Supabase**, mengeksekusinya, lalu melaporkan hasil ke tabel yang sama dan ke Telegram.

- Backup database: `pg_dump` (format custom).
- Backup Storage: `rclone sync` lewat endpoint S3-compatible Supabase (incremental, file yang terhapus/tertimpa dipindah ke folder arsip, bukan hilang).
- Notifikasi: Telegram saat job manual dimulai, sukses, dan gagal. Ditambah pengecekan mingguan bila tidak ada backup sukses dalam 35 hari.
- Restore verifikasi otomatis: setelah backup sukses, database dipulihkan ke Docker Postgres di VM dan Storage disalin ke MinIO. Ini membuktikan backup benar-benar bisa dipulihkan, dan hasilnya siap dipakai sebagai salinan darurat.

Koneksi selalu **keluar** dari VM ke Supabase. Tidak ada port yang perlu dibuka di VM.

## 2. Tujuan dan non-tujuan

**Tujuan**
- Mengeksekusi job `pending` dalam ±1 menit setelah dibuat (backup darurat dari aplikasi) atau saat jadwal bulanan.
- Menghasilkan backup yang terverifikasi minimal secara struktur (`pg_restore -l`) dan checksum.
- Selalu memberi tahu admin lewat Telegram bila ada kegagalan, termasuk bila worker sendiri tidak berjalan.
- Tidak pernah meninggalkan job berstatus `running` selamanya.
- Setelah backup sukses, otomatis memulihkan database ke Docker Postgres dan Storage ke MinIO sebagai bukti backup bisa dipulihkan.

**Non-tujuan (versi ini)**
- Mengalihkan aplikasi ke database/MinIO hasil restore secara otomatis (hasil restore hanya salinan untuk verifikasi dan darurat).
- Enkripsi backup (rekomendasi di bagian 10, belum wajib).
- Mengirim backup ke penyimpanan cloud lain.
- Menyalin backup ke NAS atau lokasi di luar VM (ditunda sampai NAS siap, lihat bagian 6).
- Menjalankan lebih dari satu backup sekaligus.

## 3. Arsitektur dan alur

```
 pg_cron / Edge Function ──insert──► backup_jobs (status = pending)
                                          ▲  │
                         poll tiap menit  │  │ klaim (FOR UPDATE SKIP LOCKED)
                                          │  ▼
 VM Ubuntu:  cron ─► flock ─► worker.sh ─┬─► pg_dump ───────► $BACKUP_ROOT/db/<TS>/db.dump
                                         ├─► rclone sync ───► $BACKUP_ROOT/storage-latest   (jika scope = full)
                                         ├─► update status ─► backup_jobs
                                         ├─► Telegram (mulai manual / sukses / gagal)
                                         └─► restore.sh ─┬─► pg_restore ──► Docker Postgres (127.0.0.1)
                                                         └─► rclone sync ─► MinIO, bucket ber-prefix (jika scope = full)

 cron mingguan ─► check-last-backup.sh ─► Telegram bila tidak ada sukses > 35 hari
```

Siklus satu job:

1. Reaper: job `running` lebih dari 6 jam ditandai `failed` (worker sebelumnya mati) dan diberitahukan ke Telegram.
2. Klaim satu job `pending` (`pending → running`, `started_at = now()`).
3. Validasi lingkungan: folder tujuan bisa ditulis dan ruang disk cukup (serta mount aktif bila `BACKUP_MOUNT` diisi).
4. `pg_dump` → validasi dump.
5. Jika `scope = full`: `rclone sync`.
6. Update `success` (ukuran, lokasi) → notifikasi.
7. Restore verifikasi (jika `RESTORE_ENABLED=true`): database ke Docker Postgres, Storage ke MinIO (hanya `scope = full`). Hasilnya diberitahukan lewat Telegram dan **tidak mengubah status job backup**.
8. Retensi.
9. Setiap kegagalan di langkah 3-5 memanggil `fail()`: status `failed` + pesan error + Telegram.

## 4. Kontrak data (ringkas)

Skema lengkap, RLS, dan Edge Function ada di `flutter/PRD.md` bagian 11. Worker memakai kolom berikut:

| Kolom | Dipakai worker untuk |
|---|---|
| `id` | identitas job |
| `status` | `pending` (dibaca) → `running` → `success`/`failed` (ditulis) |
| `scope` | `full` atau `db_only` (menentukan apakah `rclone` dijalankan) |
| `trigger_type` | `scheduled` atau `manual` (isi pesan Telegram, notifikasi "dimulai" hanya untuk `manual`) |
| `started_at`, `finished_at` | diisi worker |
| `size_bytes`, `location` | diisi saat sukses |
| `error` | diisi saat gagal (maks 500 karakter) |

Worker terhubung sebagai role Postgres `postgres` (melewati RLS).

## 5. Prasyarat VM

| Kebutuhan | Keterangan |
|---|---|
| OS | Ubuntu LTS dengan `cron`, `curl`, `flock` (paket `util-linux`) |
| `postgresql-client` | **Versi mayor harus sama atau lebih baru** dari versi Postgres project Supabase (cek di Dashboard) **maupun** server Docker Postgres. Jika repo Ubuntu terlalu lama, pasang dari repo PGDG: `apt.postgresql.org` |
| `rclone` | Dari repo resmi atau `rclone.org` |
| Jaringan keluar | Ke host database Supabase (port 5432), `<project-ref>.supabase.co` (HTTPS, S3 API), dan `api.telegram.org` (HTTPS) |
| Penyimpanan tujuan | Folder lokal di VM (`BACKUP_ROOT`, default `/srv/backups/supabase`). Ruang bebas minimal sebesar ukuran data × jumlah salinan yang disimpan. Disk/partisi data terpisah lebih baik daripada disk sistem |
| Docker Postgres (target restore database) | Container Postgres di VM dengan port dipublikasikan **hanya ke `127.0.0.1`** (mis. `127.0.0.1:5433`). Versi mayor server ≥ versi Postgres Supabase. Image `supabase/postgres` disarankan (role dan extension lebih lengkap). Lihat bagian 7 |
| MinIO (target restore Storage) | MinIO di VM (S3 API, mis. `http://127.0.0.1:9000`) dengan access key khusus yang hanya boleh mengakses bucket ber-prefix `sbrestore-*`. Lihat bagian 7 |
| IPv4/IPv6 | Koneksi langsung `db.<ref>.supabase.co` umumnya hanya IPv6. Bila VM hanya IPv4, gunakan **session pooler** (host dan user disalin dari Dashboard > Connect; port 5432, bukan transaction pooler) |

## 6. Struktur file di VM

```
/opt/backup/
├── worker.sh                 # eksekutor job (bagian 8.1)
├── notify.sh                 # fungsi notify() Telegram (bagian 8.2)
├── check-last-backup.sh      # pengecekan mingguan (bagian 8.3)
└── restore.sh                # restore verifikasi ke Docker Postgres + MinIO (bagian 8.6)

/etc/backup-worker.env        # konfigurasi + rahasia (root:backup, 640)
/etc/cron.d/backup-worker     # jadwal cron
/etc/logrotate.d/backup-worker
/var/log/backup-worker.log

$BACKUP_ROOT/                 # default /srv/backups/supabase (folder lokal VM)
├── db/<TS>/                  # db.dump, db.dump.sha256, pg_dump.log, rclone.log, restore*.log
├── storage-latest/           # salinan Storage terkini (mirror)
└── storage-deleted/<TS>/     # file yang terhapus/tertimpa di sumber
```

Jalankan sebagai user non-root khusus:
```bash
sudo useradd --system --home /opt/backup --shell /usr/sbin/nologin backup
sudo chown -R backup:backup /opt/backup
sudo touch /var/log/backup-worker.log && sudo chown backup:backup /var/log/backup-worker.log
sudo mkdir -p /srv/backups/supabase
sudo chown -R backup:backup /srv/backups
sudo chmod 750 /srv/backups/supabase
```

### Penyimpanan lokal (sementara) dan rencana pindah ke NAS

Saat ini backup disimpan di folder lokal VM (`BACKUP_ROOT`). Konsekuensinya:

- **Backup berada di VM yang sama dengan worker.** Jika disk atau VM rusak/terhapus, backup ikut hilang. Selama NAS belum siap, salin hasil backup ke tempat lain secara berkala (mis. `scp` atau `rsync` ke komputer lain), minimal setelah setiap backup bulanan.
- **Docker Postgres dan MinIO di VM yang sama bukan salinan di luar VM.** Hasil restore ikut hilang bila VM hilang. Jika Docker/MinIO berjalan di mesin lain, cukup sesuaikan alamatnya di file env.
- **Ruang disk VM terbatas.** Pantau dengan `df -h`, lalu sesuaikan `RETENTION_DAYS` dan `MIN_FREE_GB`. Jika VM punya disk/partisi data terpisah, arahkan `BACKUP_ROOT` ke sana agar disk sistem tidak penuh.
- **Saat NAS siap:** mount NAS (NFS/SMB) di VM, salin backup lama ke sana, lalu ubah `BACKUP_ROOT` ke path di NAS dan isi `BACKUP_MOUNT` dengan titik mount-nya. Skrip tidak perlu diubah.

## 7. Konfigurasi (`/etc/backup-worker.env`)

Permission wajib: `sudo chown root:backup /etc/backup-worker.env && sudo chmod 640 /etc/backup-worker.env`.

```bash
# --- Database ---
# Password harus URL-encoded bila mengandung karakter khusus (@ : / # ? dll.)
# Opsi A: koneksi langsung (IPv6)  : postgresql://postgres:PASS@db.<ref>.supabase.co:5432/postgres
# Opsi B: session pooler (IPv4)    : salin dari Dashboard > Connect (user: postgres.<ref>, port 5432)
DB_URL="postgresql://postgres:PASSWORD@db.<project-ref>.supabase.co:5432/postgres"

# --- Tujuan backup ---
BACKUP_ROOT="/srv/backups/supabase"         # folder lokal di VM (dibuat di bagian 6)
BACKUP_MOUNT=""                             # kosongkan untuk folder lokal. Isi titik mount (mis. /mnt/nas) saat memakai NAS
RETENTION_DAYS=190                          # ±6 bulan
MIN_FREE_GB=5                               # gagalkan job bila ruang bebas di bawah ini
STALE_DAYS=35                               # ambang peringatan "tidak ada backup sukses"

# --- Supabase Storage via S3 (Dashboard > Storage > S3 Connection) ---
RCLONE_CONFIG_SB_TYPE=s3
RCLONE_CONFIG_SB_PROVIDER=Other
RCLONE_CONFIG_SB_ACCESS_KEY_ID="..."
RCLONE_CONFIG_SB_SECRET_ACCESS_KEY="..."
RCLONE_CONFIG_SB_ENDPOINT="https://<project-ref>.supabase.co/storage/v1/s3"
RCLONE_CONFIG_SB_REGION="<region>"

# --- Telegram ---
TG_BOT_TOKEN="123456:ABC..."
TG_CHAT_ID="123456789"                      # grup: angka negatif

# --- Restore verifikasi ---
RESTORE_ENABLED=true                        # false untuk menonaktifkan restore otomatis

# Docker Postgres (target database). Dihubungi lewat port yang dipublikasikan, bukan docker exec
RESTORE_PGHOST="127.0.0.1"
RESTORE_PGPORT="5433"
RESTORE_PGUSER="postgres"                   # superuser container (image supabase/postgres biasanya supabase_admin)
RESTORE_PGPASSWORD="..."
RESTORE_DB_NAME="supabase_restore"          # database ini DIHAPUS dan DIBUAT ULANG setiap restore

# MinIO (target Storage)
MINIO_BUCKET_PREFIX="sbrestore-"            # bucket Supabase "avatars" -> bucket MinIO "sbrestore-avatars"
RCLONE_CONFIG_MINIO_TYPE=s3
RCLONE_CONFIG_MINIO_PROVIDER=Minio
RCLONE_CONFIG_MINIO_ACCESS_KEY_ID="..."
RCLONE_CONFIG_MINIO_SECRET_ACCESS_KEY="..."
RCLONE_CONFIG_MINIO_ENDPOINT="http://127.0.0.1:9000"
```

### Menyiapkan bot Telegram
1. Chat **@BotFather** → `/newbot` → simpan token.
2. Kirim satu pesan ke bot (atau tambahkan bot ke grup lalu kirim pesan di sana).
3. Ambil `chat_id`: `curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates"` → cari `"chat":{"id":...}`.

### Menyiapkan Docker Postgres (target restore database)

Jika Anda sudah punya container Postgres, cukup pastikan port hanya dibuka ke localhost lalu isi variabel `RESTORE_PG*`. Contoh container baru:

```bash
docker run -d --name pg-restore --restart unless-stopped \
  -e POSTGRES_PASSWORD='GANTI_PASSWORD' \
  -p 127.0.0.1:5433:5432 \
  -v pg-restore-data:/var/lib/postgresql/data \
  supabase/postgres:<tag-sesuai-versi>
```

- Pilih tag dengan versi mayor yang sama dengan project Supabase (cek di Docker Hub). Image Postgres polos (`postgres:<versi>`) juga bisa. `restore.sh` membuat role `anon`, `authenticated`, `service_role`, `authenticator` bila belum ada, tetapi extension khusus Supabase (`pg_cron`, `pgsodium`, `pg_graphql`, dan sejenisnya) tidak tersedia sehingga `pg_restore` mencatat error yang diabaikan.
- Worker memakai `psql`/`pg_restore` dari VM lewat port yang dipublikasikan. User `backup` **tidak perlu masuk grup `docker`** (grup itu setara akses root).
- Database `RESTORE_DB_NAME` dihapus dan dibuat ulang setiap restore (`drop database ... with (force)`, butuh Postgres 13 ke atas). Jangan memakai nama database yang berisi data lain.
- Uji koneksi: `PGPASSWORD='...' psql -h 127.0.0.1 -p 5433 -U <user> -d postgres -c "select 1"`.

### Menyiapkan MinIO (target restore Storage)

Buat user dan access key khusus yang hanya boleh mengakses bucket ber-prefix, supaya restore tidak pernah menyentuh bucket MinIO lain milik Anda. `sbrestore-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::sbrestore-*", "arn:aws:s3:::sbrestore-*/*"]
    }
  ]
}
```

Perintah `mc` (nama sub-perintah bisa berbeda antar versi, cek `mc admin policy --help`; `local` adalah alias `mc` untuk MinIO Anda):

```bash
mc admin policy create local sbrestore-policy sbrestore-policy.json
mc admin user add local backup-restore 'GANTI_SECRET'
mc admin policy attach local sbrestore-policy --user backup-restore
```

- Username dan secret itu dipakai sebagai `RCLONE_CONFIG_MINIO_ACCESS_KEY_ID` dan `RCLONE_CONFIG_MINIO_SECRET_ACCESS_KEY`. Awalan di policy harus sama dengan `MINIO_BUCKET_PREFIX`.
- Jika rclone mengeluh akses ditolak saat membuat bucket, tambahkan `s3:ListAllMyBuckets` ke policy.
- Nama bucket MinIO: huruf kecil, angka, titik, strip, 3 sampai 63 karakter. Bucket Supabase dengan nama yang tidak memenuhi aturan ini dilaporkan gagal di Telegram.
- Uji: `rclone lsd minio:` (dengan env dimuat).

## 8. Skrip

### 8.1 `/opt/backup/worker.sh`

```bash
#!/usr/bin/env bash
set -uo pipefail
set -a; source /etc/backup-worker.env; set +a
source /opt/backup/notify.sh

: "${RETENTION_DAYS:=190}"
: "${MIN_FREE_GB:=5}"
HOST=$(hostname)
PSQL=(psql "$DB_URL" -qAtX -v ON_ERROR_STOP=1)

# 1. Reaper: job 'running' > 6 jam dianggap mati agar tidak memblokir job baru
REAPED=$("${PSQL[@]}" <<'SQL'
update backup_jobs
set status='failed', finished_at=now(), error='worker timeout/crash'
where status='running' and started_at < now() - interval '6 hours'
returning id;
SQL
)
[ -n "$REAPED" ] && notify "⚠️ [$HOST] Job backup dianggap mati (running > 6 jam): $REAPED"

# 2. Klaim satu job pending (aman walau ada lebih dari satu worker)
ROW=$("${PSQL[@]}" <<'SQL'
update backup_jobs set status='running', started_at=now()
where id = (
  select id from backup_jobs
  where status='pending'
  order by created_at
  limit 1
  for update skip locked
)
returning id, scope, trigger_type;
SQL
)
[ -z "$ROW" ] && exit 0
IFS='|' read -r JOB_ID SCOPE TRIGGER <<< "$ROW"

TS=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_ROOT/db/$TS"

fail() {
  "${PSQL[@]}" -v id="$JOB_ID" -v err="${1:0:500}" <<'SQL'
update backup_jobs set status='failed', finished_at=now(), error=:'err' where id=:'id';
SQL
  notify "❌ [$HOST] Backup Supabase GAGAL ($TRIGGER, $SCOPE)
Job: $JOB_ID
Penyebab: ${1:0:500}"
  exit 1
}

[ "$TRIGGER" = "manual" ] && notify "🔄 [$HOST] Backup manual dimulai (cakupan: $SCOPE)"

# 3. Validasi lingkungan
mkdir -p "$BACKUP_ROOT" || fail "gagal membuat BACKUP_ROOT: $BACKUP_ROOT"
if [ -n "${BACKUP_MOUNT:-}" ]; then   # hanya jika memakai NAS/mount eksternal
  mountpoint -q "$BACKUP_MOUNT" || fail "BACKUP_MOUNT tidak ter-mount: $BACKUP_MOUNT"
fi
FREE_GB=$(df -BG --output=avail "$BACKUP_ROOT" | tail -n 1 | tr -dc '0-9')
[ "${FREE_GB:-0}" -ge "$MIN_FREE_GB" ] || fail "ruang disk kurang: ${FREE_GB}GB tersisa (minimal ${MIN_FREE_GB}GB)"
mkdir -p "$DEST" "$BACKUP_ROOT/storage-latest" "$BACKUP_ROOT/storage-deleted/$TS" \
  || fail "gagal membuat folder backup"

# 4. Database
pg_dump "$DB_URL" -Fc --no-owner --no-acl -f "$DEST/db.dump" 2> "$DEST/pg_dump.log" \
  || fail "pg_dump gagal: $(tail -n 3 "$DEST/pg_dump.log")"
pg_restore -l "$DEST/db.dump" > /dev/null 2>> "$DEST/pg_dump.log" \
  || fail "db.dump tidak valid (pg_restore -l gagal)"
sha256sum "$DEST/db.dump" > "$DEST/db.dump.sha256"
SIZE=$(stat -c%s "$DEST/db.dump")

# 5. Storage (dilewati untuk scope db_only)
if [ "$SCOPE" = "full" ]; then
  rclone sync sb: "$BACKUP_ROOT/storage-latest" \
    --backup-dir "$BACKUP_ROOT/storage-deleted/$TS" \
    --transfers 8 --checkers 16 2> "$DEST/rclone.log" \
    || fail "rclone gagal: $(tail -n 3 "$DEST/rclone.log")"
  SIZE=$(( SIZE + $(du -sb "$BACKUP_ROOT/storage-latest" | cut -f1) ))
fi

# 6. Sukses
"${PSQL[@]}" -v id="$JOB_ID" -v size="$SIZE" -v loc="$DEST" <<'SQL'
update backup_jobs
set status='success', finished_at=now(), size_bytes=:size, location=:'loc'
where id=:'id';
SQL
notify "✅ [$HOST] Backup Supabase selesai ($TRIGGER, $SCOPE)
Ukuran: $(( SIZE / 1048576 )) MB
Lokasi: $DEST"

# 7. Restore verifikasi ke Docker Postgres + MinIO (tidak mengubah status job backup)
if [ "${RESTORE_ENABLED:-false}" = "true" ]; then
  /opt/backup/restore.sh "$DEST" "$SCOPE" || true
fi

# 8. Retensi: hapus yang lebih tua dari RETENTION_DAYS, tapi selalu sisakan 3 backup db terbaru
ls -1dt "$BACKUP_ROOT"/db/*/ 2>/dev/null | tail -n +4 | while read -r d; do
  [ -n "$(find "$d" -maxdepth 0 -mtime +"$RETENTION_DAYS")" ] && rm -rf "$d"
done
find "$BACKUP_ROOT/storage-deleted" -mindepth 1 -maxdepth 1 -mtime +"$RETENTION_DAYS" -exec rm -rf {} +
```

### 8.2 `/opt/backup/notify.sh`

```bash
notify() {
  curl -fsS --max-time 15 -X POST \
    "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=$1" > /dev/null \
    || echo "$(date -Is) notifikasi telegram gagal terkirim" >&2
}
```
Kegagalan Telegram tidak boleh menggagalkan backup. Cukup dicatat ke log.

### 8.3 `/opt/backup/check-last-backup.sh`

Menangkap kasus yang tidak bisa ditangkap `fail()`: worker/cron/VM mati sehingga tidak ada job yang pernah diproses.

```bash
#!/usr/bin/env bash
set -uo pipefail
set -a; source /etc/backup-worker.env; set +a
source /opt/backup/notify.sh
: "${STALE_DAYS:=35}"

DAYS=$(psql "$DB_URL" -qAtX -c "
  select coalesce(extract(day from now() - max(finished_at))::int, 9999)
  from backup_jobs where status = 'success'")

if [ "${DAYS:-9999}" -gt "$STALE_DAYS" ]; then
  notify "⚠️ [$(hostname)] Belum ada backup Supabase yang sukses dalam $DAYS hari. Cek worker, cron, dan koneksi."
fi
```

### 8.4 Jadwal `/etc/cron.d/backup-worker`

```cron
* * * * * backup flock -n /tmp/backup-worker.lock /opt/backup/worker.sh >> /var/log/backup-worker.log 2>&1
0 9 * * 1 backup /opt/backup/check-last-backup.sh >> /var/log/backup-worker.log 2>&1
```
`flock -n` membuat cron melewati menit berikutnya bila backup sebelumnya masih berjalan. Waktu cron mengikuti zona waktu server (cek dengan `timedatectl`).

### 8.5 `/etc/logrotate.d/backup-worker`

```
/var/log/backup-worker.log {
  monthly
  rotate 6
  compress
  missingok
  notifempty
}
```

### 8.6 `/opt/backup/restore.sh`

Dipanggil otomatis oleh `worker.sh` setelah backup sukses. Bisa juga dijalankan manual untuk folder backup mana pun:

```bash
sudo -u backup /opt/backup/restore.sh /srv/backups/supabase/db/20261101-020000 full
```

Restore Storage selalu bersumber dari `storage-latest/` yang terkini, bukan dari tanggal backup tertentu.

```bash
#!/usr/bin/env bash
# Pemakaian: restore.sh <folder-backup-db> [full|db_only]
set -uo pipefail
set -a; source /etc/backup-worker.env; set +a
source /opt/backup/notify.sh

DEST="${1:?folder backup db wajib diisi}"
SCOPE="${2:-full}"
HOST=$(hostname)
: "${RESTORE_DB_NAME:=supabase_restore}"
: "${MINIO_BUCKET_PREFIX:=sbrestore-}"

LOG="$DEST/restore.log"
: > "$LOG"

rfail() {
  notify "⚠️ [$HOST] Restore verifikasi GAGAL (backup tetap tersimpan)
Backup: $DEST
Tahap: $1
Detail: ${2:0:400}"
  exit 1
}

# Cegah dua restore berjalan bersamaan
exec 9>/tmp/restore.lock
flock -n 9 || rfail "kunci" "restore lain sedang berjalan"

# Koneksi ke Docker Postgres lewat port yang dipublikasikan
export PGHOST="$RESTORE_PGHOST" PGPORT="$RESTORE_PGPORT" \
       PGUSER="$RESTORE_PGUSER" PGPASSWORD="$RESTORE_PGPASSWORD"
RPSQL=(psql -qAtX -v ON_ERROR_STOP=1)

# 1. Integritas file
[ -f "$DEST/db.dump" ] || rfail "persiapan" "db.dump tidak ditemukan di $DEST"
(cd "$DEST" && sha256sum -c db.dump.sha256 --status) \
  || rfail "checksum" "db.dump tidak cocok dengan db.dump.sha256"

# 2. Siapkan database target (dihapus lalu dibuat ulang) dan role dasar Supabase
"${RPSQL[@]}" -d postgres -c "drop database if exists \"$RESTORE_DB_NAME\" with (force)" >> "$LOG" 2>&1 \
  || rfail "siapkan database" "$(tail -n 3 "$LOG")"
"${RPSQL[@]}" -d postgres -c "create database \"$RESTORE_DB_NAME\"" >> "$LOG" 2>&1 \
  || rfail "siapkan database" "$(tail -n 3 "$LOG")"
"${RPSQL[@]}" -d postgres >> "$LOG" 2>&1 <<'SQL' || rfail "buat role" "$(tail -n 3 "$LOG")"
do $$
declare r text;
begin
  foreach r in array array['anon','authenticated','service_role','authenticator'] loop
    if not exists (select 1 from pg_roles where rolname = r) then
      execute format('create role %I nologin', r);
    end if;
  end loop;
end $$;
SQL

# 3. Restore database. Error objek khusus Supabase (extension dll.) wajar, jadi dihitung, tidak digagalkan
pg_restore -d "$RESTORE_DB_NAME" --no-owner --no-acl "$DEST/db.dump" 2> "$DEST/restore-db.log"
if grep -qiE 'could not connect|connection to server|password authentication failed' "$DEST/restore-db.log"; then
  rfail "restore database" "koneksi/otentikasi gagal: $(tail -n 3 "$DEST/restore-db.log")"
fi
ERRS=$(grep -c '^pg_restore: error' "$DEST/restore-db.log")

# 4. Verifikasi: jumlah tabel schema public hasil restore harus sama dengan isi dump
EXPECT=$(pg_restore -l "$DEST/db.dump" | grep -c ' TABLE public ')
GOT=$("${RPSQL[@]}" -d "$RESTORE_DB_NAME" -c \
  "select count(*) from information_schema.tables where table_schema='public' and table_type='BASE TABLE'")
[ "$GOT" = "$EXPECT" ] \
  || rfail "verifikasi database" "tabel public: diharapkan $EXPECT, hasil ${GOT:-?}; error pg_restore: $ERRS (lihat $DEST/restore-db.log)"

# 5. Storage -> MinIO (hanya scope full). Tiap bucket ke bucket ber-prefix. Tidak pernah menyentuh root MinIO
BUCKETS=0
if [ "$SCOPE" = "full" ]; then
  SRC="$BACKUP_ROOT/storage-latest"
  FAILED=""
  for d in "$SRC"/*/; do
    [ -d "$d" ] || continue
    b=$(basename "$d")
    dst="${MINIO_BUCKET_PREFIX}${b}"
    BUCKETS=$((BUCKETS + 1))
    { rclone sync "$d" "minio:$dst" --transfers 8 --checkers 16 \
        && rclone check "$d" "minio:$dst" --size-only; } >> "$DEST/restore-minio.log" 2>&1 \
      || FAILED="$FAILED $b"
  done
  [ -z "$FAILED" ] || rfail "storage ke MinIO" "bucket gagal:$FAILED (lihat $DEST/restore-minio.log)"
  STORAGE_MSG="$BUCKETS bucket → MinIO (prefix $MINIO_BUCKET_PREFIX)"
else
  STORAGE_MSG="dilewati (db_only)"
fi

notify "✅ [$HOST] Restore verifikasi selesai
Database: $GOT tabel public → $RESTORE_DB_NAME ($ERRS error pg_restore diabaikan)
Storage: $STORAGE_MSG"
```

```bash
chmod +x /opt/backup/restore.sh
```

## 9. Kebutuhan fungsional worker

| ID | Kebutuhan |
|---|---|
| W-1 | Mengambil paling banyak satu job `pending` per eksekusi, urut `created_at`, memakai `FOR UPDATE SKIP LOCKED`. |
| W-2 | Menandai `running` + `started_at` saat klaim. Menandai `success`/`failed` + `finished_at` di akhir. |
| W-3 | `scope = db_only` hanya menjalankan `pg_dump`. `scope = full` menjalankan `pg_dump` lalu `rclone sync`. |
| W-4 | `pg_dump` memakai format custom (`-Fc`), `--no-owner --no-acl`, lalu divalidasi `pg_restore -l` dan dibuatkan `sha256`. |
| W-5 | `rclone sync` memakai `--backup-dir` ke `storage-deleted/<TS>` supaya file yang terhapus di sumber tidak ikut hilang dari backup. |
| W-6 | Sebelum menulis, verifikasi `BACKUP_ROOT` bisa dibuat/ditulis dan ruang bebas di filesystem-nya ≥ `MIN_FREE_GB`. Jika `BACKUP_MOUNT` diisi, verifikasi juga mount aktif. Jika gagal, job `failed`. |
| W-7 | Setiap kegagalan menulis `error` (≤ 500 karakter) dan mengirim Telegram. Tidak ada kegagalan yang senyap. |
| W-8 | Reaper menandai job `running` > 6 jam sebagai `failed` dan mengirim Telegram. |
| W-9 | Telegram: pesan "dimulai" hanya untuk job `manual`. Pesan sukses dan gagal untuk semua job. |
| W-10 | Retensi `RETENTION_DAYS` (default 190), selalu menyisakan minimal 3 backup db terbaru. |
| W-11 | Pengecekan mingguan memberi peringatan bila tidak ada backup sukses dalam `STALE_DAYS` (default 35). |
| W-12 | Tidak ada rahasia yang masuk ke pesan Telegram, log aplikasi, atau kolom `error` (jangan mencetak `DB_URL`, password, atau kunci). |
| W-13 | Jika `RESTORE_ENABLED=true`, setelah backup `success` worker menjalankan `restore.sh`. Kegagalan restore **tidak** mengubah status job backup, hanya mengirim Telegram ⚠️. |
| W-14 | Restore database: verifikasi checksum, hapus dan buat ulang `RESTORE_DB_NAME`, pastikan role dasar ada, lalu `pg_restore --no-owner --no-acl`. Dianggap sukses bila jumlah tabel `public` hasil restore sama dengan isi dump. Error `pg_restore` dihitung dan dilaporkan, tidak otomatis menggagalkan. |
| W-15 | Restore Storage hanya untuk `scope = full`: tiap bucket di `storage-latest/` di-sync ke MinIO dengan nama `MINIO_BUCKET_PREFIX + <bucket>`, lalu diverifikasi (`rclone check --size-only`). |
| W-16 | Restore ke MinIO tidak boleh menyentuh bucket di luar prefix: tidak ada sync pada root MinIO, dan access key dibatasi policy ke `sbrestore-*`. |
| W-17 | `restore.sh` dapat dijalankan manual untuk folder backup mana pun, dan tidak berjalan dua kali bersamaan (`flock`). |

## 10. Keamanan

- `/etc/backup-worker.env` berizin `640` (`root:backup`). Jangan di-commit ke git.
- Token bot Telegram setara password. Jika bocor: `/revoke` di BotFather.
- Gunakan kunci S3 Supabase khusus untuk backup. Cabut bila perlu tanpa memengaruhi aplikasi.
- Backup berisi data user. Batasi akses ke `$BACKUP_ROOT` (`chmod 750`, pemilik `backup`).
- Rekomendasi lanjutan: enkripsi `db.dump` dengan `age` atau `gpg` bila disalin ke luar VM atau NAS bersama.
- VM tidak membuka port masuk apa pun untuk fitur ini.
- Port Docker Postgres hanya dipublikasikan ke `127.0.0.1`. Jangan dibuka ke jaringan.
- Docker Postgres hasil restore berisi data user (termasuk `auth.users`) dan harus diperlakukan sama sensitifnya dengan database produksi. Pakai password yang kuat.
- Access key MinIO khusus dengan policy ke prefix `sbrestore-*` saja, bukan kunci admin MinIO.

## 11. Prosedur restore dan uji restore (manual)

`restore.sh` (bagian 8.6) memverifikasi tiap backup secara otomatis ke Docker Postgres dan MinIO. Prosedur manual di bawah dipakai untuk pemulihan sungguhan ke project Supabase baru atau target lain, dan sebaiknya dicoba **sekali** setelah setup, lalu minimal setahun sekali.

1. Buat project Supabase kosong (atau instance Postgres lokal dengan versi yang sama).
2. Verifikasi checksum: `cd $BACKUP_ROOT/db/<TS> && sha256sum -c db.dump.sha256`.
3. Database: `pg_restore --no-owner --no-acl -d "<URL_TARGET>" db.dump`. Pesan error untuk objek bawaan Supabase yang sudah ada di target bisa muncul. Periksa bahwa tabel dan data aplikasi (`public`) lengkap.
4. Storage: `rclone copy $BACKUP_ROOT/storage-latest sbtarget:` (konfigurasi remote target via env `RCLONE_CONFIG_SBTARGET_*` seperti pada bagian 7).
5. Catat durasi dan temuan, perbarui dokumen ini bila ada langkah yang perlu disesuaikan.

## 12. Biaya dan kuota

- Semua komponen di sisi VM gratis (software open source, memakai VM yang sudah ada, biaya hanya ruang disk VM).
- Backup bulanan hanya menarik data sebesar database + file baru sekali per bulan. Ini kecil dibanding kuota egress plan Free (cek angka terbaru di `supabase.com/pricing`).
- Plan Free: project di-pause setelah 1 minggu tanpa aktivitas, dan tidak ada backup harian bawaan. Plan Pro menghilangkan pause dan menambah backup bawaan sebagai lapisan tambahan.
- Setiap backup (terutama `pg_dump`) mengunduh data penuh melalui jaringan. Pantau penggunaan egress bila data mendekati kuota.
- Restore otomatis menambah pemakaian disk VM: database hasil restore di Docker Postgres dan salinan Storage di MinIO, kira-kira sebesar ukuran data lagi. Restore memakai file lokal hasil backup, jadi tidak menambah egress Supabase.

## 13. Rencana kerja

- [ ] 1. Siapkan VM: paket (`postgresql-client` versi sesuai, `rclone`, `curl`), user `backup`, folder tujuan `BACKUP_ROOT`
- [ ] 2. Buat bot Telegram, dapatkan token dan `chat_id`
- [ ] 3. Siapkan Docker Postgres (target restore) dan uji koneksi (bagian 7)
- [ ] 4. Siapkan MinIO: policy dan access key ber-prefix, uji `rclone lsd minio:` (bagian 7)
- [ ] 5. Buat `/etc/backup-worker.env` (bagian 7) dan atur izin
- [ ] 6. Pasang `notify.sh`, `worker.sh`, `restore.sh`, `check-last-backup.sh` di `/opt/backup` (`chmod +x`)
- [ ] 7. Uji manual satu per satu (bagian 14, langkah 1-3), lalu uji `restore.sh` manual (langkah 19) sebelum mengaktifkan cron
- [ ] 8. Pasang `/etc/cron.d/backup-worker` dan logrotate
- [ ] 9. Uji end-to-end dengan aplikasi Flutter (bagian 14, langkah 4-9 dan 14-18)
- [ ] 10. Lakukan uji restore manual ke project Supabase baru (bagian 11)
- [ ] 11. Atur salinan berkala ke luar VM selama NAS belum siap
- [ ] 12. (Nanti, saat NAS siap) Pindahkan `BACKUP_ROOT` ke NAS (bagian 6)

## 14. Skenario uji penerimaan

1. **Telegram:** `source /opt/backup/notify.sh` (setelah memuat env) lalu `notify "tes"` → pesan muncul di Telegram.
2. **Koneksi DB:** `psql "$DB_URL" -c "select 1"` berhasil dari VM dengan user `backup`.
3. **Storage:** `rclone lsd sb:` menampilkan bucket.
4. **Job manual full:** tekan "Backup sekarang" (Lengkap) di aplikasi → ≤ 1 menit status `running`, Telegram "dimulai", lalu `success` + Telegram sukses. `db.dump`, `db.dump.sha256`, dan isi `storage-latest` ada.
5. **Job manual db_only:** hanya `db.dump` baru yang muncul, `storage-latest` tidak berubah.
6. **Gagal (DB):** ubah password `DB_URL` sementara → job `failed`, `error` terisi, Telegram ❌ masuk.
7. **Gagal (folder):** cabut hak tulis user `backup` ke `BACKUP_ROOT` → job `failed` dengan pesan "gagal membuat folder backup" dan Telegram ❌ masuk. Setelah memakai NAS (`BACKUP_MOUNT` terisi), uji juga unmount → job `failed` dengan pesan mount.
8. **Gagal (disk):** set `MIN_FREE_GB` sangat besar → job `failed` dengan pesan ruang disk.
9. **Reaper:** set manual satu job `running` dengan `started_at` 7 jam lalu → run berikutnya menandainya `failed` + Telegram ⚠️.
10. **Anti-tumpang-tindih:** jalankan dua `worker.sh` bersamaan → hanya satu memproses job (`flock` / `SKIP LOCKED`).
11. **Dead-man check:** jalankan `check-last-backup.sh` saat belum ada backup sukses → Telegram ⚠️. Setelah ada sukses → senyap.
12. **Retensi:** buat folder uji berusia > `RETENTION_DAYS` → terhapus setelah backup sukses, dan 3 backup terbaru tidak pernah terhapus.
13. **Jadwal bulanan:** uji `pg_cron` (lihat `flutter/PRD.md` 11.4) dengan menjalankan `insert` manual `trigger_type='scheduled'` → worker memprosesnya tanpa notifikasi "dimulai".
14. **Restore database otomatis:** setelah job sukses, Telegram "Restore verifikasi selesai" masuk. Di Docker Postgres, database `supabase_restore` ada dan jumlah tabel `public` sama dengan isi dump.
15. **Restore Storage otomatis (scope `full`):** bucket `sbrestore-<nama>` muncul di MinIO dengan jumlah dan ukuran file sama dengan `storage-latest`. Bucket MinIO lain yang sudah ada tidak berubah.
16. **Scope `db_only`:** database ter-restore, tidak ada perubahan di MinIO, dan Telegram menyebut storage dilewati.
17. **Restore gagal tidak membatalkan backup:** hentikan container Docker Postgres → job backup tetap `success` di aplikasi dan Telegram ⚠️ restore gagal masuk.
18. **Nonaktif:** `RESTORE_ENABLED=false` → tidak ada restore dan tidak ada pesan restore.
19. **Restore manual:** `sudo -u backup /opt/backup/restore.sh /srv/backups/supabase/db/<TS> full` berhasil dan menghasilkan pesan yang sama.
20. **Checksum rusak:** ubah satu byte di salinan `db.dump` → restore berhenti di tahap checksum dan Telegram ⚠️ masuk.

## 15. Risiko dan mitigasi

| Risiko | Mitigasi |
|---|---|
| Versi `pg_dump` lebih lama dari server | Pasang client dari PGDG, samakan versi mayor |
| Backup hanya ada di VM yang sama (disk/VM rusak atau terhapus, backup ikut hilang) | Salin manual berkala ke luar VM sampai NAS siap, lalu pindahkan `BACKUP_ROOT` ke NAS (bagian 6) |
| Disk VM penuh karena backup | Cek `MIN_FREE_GB` (W-6), atur `RETENTION_DAYS`, pantau `df -h`, pakai partisi data terpisah bila ada |
| NAS (nanti) lepas sehingga backup tertulis ke disk lokal | Isi `BACKUP_MOUNT` agar worker memeriksa `mountpoint -q` sebelum menulis (W-6) |
| Worker/cron mati diam-diam | Pengecekan mingguan 35 hari (W-11) |
| Job menggantung `running` | Reaper 6 jam (W-8) |
| Kegagalan Telegram | Hanya dicatat di log, status tetap tersimpan di `backup_jobs` dan terlihat di aplikasi |
| Kuota egress/pause di plan Free | Pantau pemakaian, pertimbangkan Pro bila data membesar |
| Kunci/password bocor | Izin file 640, kunci S3 khusus backup, rotasi berkala |
| Restore menimpa bucket MinIO lain | Sync hanya per bucket ber-prefix, access key dibatasi policy ke `sbrestore-*` (W-16) |
| Restore menimpa data lain di Docker Postgres | Pakai database khusus `RESTORE_DB_NAME` yang dihapus dan dibuat ulang tiap restore. Jangan pakai nama database yang berisi data lain |
| Restore lama menahan job berikutnya (worker masih memegang lock) | Backup darurat berikutnya menunggu restore selesai. Nonaktifkan dengan `RESTORE_ENABLED=false` bila data besar |
| Extension/role khusus Supabase tidak ada di Postgres polos | Pakai image `supabase/postgres`, atau terima error yang dihitung dan dilaporkan. Verifikasi lewat jumlah tabel `public` |
