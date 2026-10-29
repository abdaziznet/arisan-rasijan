# PRD — Fitur Backup Supabase di Aplikasi Flutter

| | |
|---|---|
| Versi | 1.0 (siap implementasi) |
| Tanggal | 14 Oktober 2026 |
| Cakupan dokumen | Aplikasi Flutter + backend Supabase (tabel, RLS, Edge Function, jadwal) |
| Dokumen pasangan | `backup-worker.md` (worker di VM Ubuntu yang mengeksekusi backup) |

---

## 1. Ringkasan

Aplikasi Flutter yang sudah terintegrasi Supabase perlu fitur backup **full database + Storage** Supabase.
Aplikasi **tidak mengeksekusi backup**. Aplikasi hanya:

1. meminta backup (membuat *job*) lewat Supabase Edge Function,
2. menampilkan status dan riwayat job secara real-time.

Eksekusi backup (`pg_dump`, `rclone`) dilakukan oleh worker di VM Ubuntu (lihat `worker/PRD.md`).
Alasan: `pg_dump` butuh kredensial Postgres dan backup Storage butuh akses ke semua bucket. Keduanya tidak boleh ada di aplikasi mobile.

## 2. Latar belakang dan keputusan

| Keputusan | Nilai |
|---|---|
| Frekuensi backup rutin | **1 kali sebulan**, otomatis lewat `pg_cron` (tanggal 1, 02:00 WIB) |
| Backup darurat | Tombol **"Backup sekarang"** di halaman admin, diambil worker dalam ±1 menit |
| Cakupan backup | `full` (database + Storage) atau `db_only` (database saja, lebih cepat) |
| Notifikasi | Telegram, dikirim oleh **worker** (bukan aplikasi) |
| Pemicu eksekusi | Worker menarik (*pull*) job dari database. Tidak ada port yang dibuka di VM |
| Hak akses | Hanya user dengan `profiles.role = 'admin'`; role dijaga agar anggota tidak dapat menaikkan hak aksesnya sendiri |

## 3. Tujuan dan non-tujuan

**Tujuan**
- Admin dapat memicu backup darurat dari aplikasi kapan saja.
- Admin dapat melihat status dan riwayat backup tanpa membuka server.
- Admin langsung tahu bila backup terakhir sudah terlalu lama atau gagal.
- Tidak ada kredensial Postgres, `service_role`, maupun kunci S3 di aplikasi.

**Non-tujuan (versi ini)**
- Restore dari dalam aplikasi.
- Mengunduh file backup ke perangkat.
- Mengubah jadwal backup dari aplikasi.
- Membatalkan job yang sedang berjalan.
- Push notification (notifikasi sudah ditangani Telegram oleh worker).

## 4. Pengguna

| Peran | Akses |
|---|---|
| Admin | Melihat halaman Backup, riwayat, dan menekan "Backup sekarang" |
| User biasa | Tidak melihat menu Backup. Secara server juga ditolak (RLS dan Edge Function) |

## 5. Arsitektur

```
 Flutter (admin)
   │  1. invoke('request-backup') + JWT
   ▼
 Edge Function request-backup ── 2. insert (service role) ──► Postgres: backup_jobs
   ▲                                                              │        ▲
   │                                                              │        │ 3. poll + update status
   └──────────── 4. Realtime (status berubah) ◄───────────────────┘        │ (koneksi KELUAR dari VM)
                                                                           │
                                                               VM Ubuntu: worker.sh
                                                               pg_dump + rclone sync + Telegram
```

Status job: `pending → running → success | failed`.
Hanya boleh ada **satu job aktif** (`pending`/`running`) pada satu waktu (dijamin unique index di database).

## 6. User stories dan acceptance criteria

**US-1 — Backup darurat**
Sebagai admin, saya ingin menekan "Backup sekarang" saat kondisi urgent supaya backup dibuat hari itu juga.
- AC: dialog konfirmasi muncul dengan pilihan cakupan (`Lengkap` / `Database saja`) dan catatan opsional.
- AC: setelah konfirmasi, job baru berstatus `pending` muncul di riwayat dalam < 2 detik.
- AC: snackbar menyatakan worker mengambil job dalam ±1 menit.

**US-2 — Pantau status**
Sebagai admin, saya ingin melihat status job berubah otomatis tanpa me-refresh.
- AC: perubahan `pending → running → success/failed` tampil tanpa aksi manual.
- AC: job `running` menampilkan indikator progres tak-tentu (spinner).

**US-3 — Cegah backup ganda**
- AC: tombol "Backup sekarang" nonaktif selama ada job `pending`/`running`.
- AC: jika tetap tertekan (race condition) dan server membalas 409, tampil pesan "Masih ada backup yang berjalan".

**US-4 — Peringatan backup usang**
- AC: banner di atas halaman menampilkan "Backup sukses terakhir: N hari lalu".
- AC: banner berwarna peringatan jika N > 35. Banner berwarna error jika belum pernah ada backup sukses.

**US-5 — Detail dan diagnosis**
- AC: ketuk item riwayat membuka detail: id, status, jenis pemicu, cakupan, catatan, waktu dibuat/mulai/selesai, durasi, ukuran, lokasi, dan pesan error lengkap bila `failed`.

## 7. Kebutuhan fungsional

| ID | Kebutuhan |
|---|---|
| FR-1 | Menu/halaman Backup tampil jika profil anggota memiliki `role == 'admin'`. Penegakan server dilakukan kembali oleh RLS dan Edge Function berdasarkan `profiles.role`. |
| FR-2 | Riwayat: 10 job terbaru lewat Supabase Realtime (`.stream()`), urut `created_at` menurun. |
| FR-3 | Banner "backup sukses terakhir" diambil dengan query terpisah (`status = 'success'`, urut `finished_at` menurun, limit 1) dan dimuat ulang saat ada job yang berubah menjadi `success`. |
| FR-4 | Tombol "Backup sekarang" membuka dialog: `SegmentedButton` cakupan (default `full`) + `TextField` catatan (maks 200 karakter, opsional) + tombol Batal/Mulai. |
| FR-5 | Panggilan ke Edge Function: `supabase.functions.invoke('request-backup', body: {scope, note})`. |
| FR-6 | Penanganan error (lihat tabel 9.3). Pesan dalam Bahasa Indonesia. |
| FR-7 | Jika stream Realtime terputus/error, fallback ke polling `select` tiap 10 detik selama ada job aktif. |
| FR-8 | Item riwayat menampilkan: ikon status, label pemicu (`Terjadwal`/`Manual`), cakupan, waktu dibuat (zona waktu perangkat), durasi, ukuran (MB), dan satu baris error bila ada. |
| FR-9 | Tampilkan state: loading, kosong ("Belum ada backup"), error (dengan tombol coba lagi). |

## 8. Spesifikasi UI

**Halaman "Backup" (admin)**
```
┌────────────────────────────────────┐
│ Backup                              │
│ ┌────────────────────────────────┐ │
│ │ Backup sukses terakhir: 12 hari │ │  ← banner (normal / peringatan / error)
│ └────────────────────────────────┘ │
│ [ Backup sekarang ]                │  ← nonaktif jika ada job aktif
│                                    │
│ Riwayat                             │
│ ● Sukses   Manual · Lengkap  4,2 MB │
│ ◌ Berjalan Terjadwal · Lengkap      │
│ ✕ Gagal    Manual · DB saja         │
│   pg_dump gagal: connection...      │
└────────────────────────────────────┘
```

| Status | Ikon | Warna |
|---|---|---|
| `pending` | jam (`Icons.schedule`) | netral |
| `running` | spinner kecil | netral |
| `success` | centang (`Icons.check_circle`) | hijau |
| `failed` | silang (`Icons.error`) | merah |

**Teks UI (Bahasa Indonesia)**
- Judul dialog: "Backup sekarang"
- Opsi cakupan: "Lengkap" (database + storage), "Database saja" (lebih cepat)
- Bantuan di bawah opsi "Database saja": "Storage tidak diperbarui. Salinan storage tetap dari backup lengkap terakhir."
- Snackbar sukses: "Job dibuat. Worker mengambilnya dalam ±1 menit."
- 409: "Masih ada backup yang berjalan"
- 403: "Anda tidak punya akses untuk fitur ini"
- 401: "Sesi berakhir, silakan login ulang"
- Lainnya: "Gagal memulai backup. Coba lagi."

## 9. Kontrak data dan API

### 9.1 Tabel `public.backup_jobs`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid PK | default `gen_random_uuid()` |
| `status` | text | `pending` \| `running` \| `success` \| `failed` |
| `trigger_type` | text | `scheduled` (default) \| `manual` |
| `scope` | text | `full` (default) \| `db_only` |
| `note` | text null | catatan dari admin |
| `requested_by` | uuid null | `auth.users.id` pemicu manual |
| `created_at` | timestamptz | default `now()` |
| `started_at` | timestamptz null | diisi worker |
| `finished_at` | timestamptz null | diisi worker |
| `size_bytes` | bigint null | diisi worker saat sukses |
| `location` | text null | path hasil backup di server |
| `error` | text null | diisi worker saat gagal |

### 9.2 Edge Function `request-backup`

`POST {SUPABASE_URL}/functions/v1/request-backup`
Header: `Authorization: Bearer <JWT user>` (otomatis oleh `supabase_flutter`).

Body (JSON, semua opsional):
```json
{ "scope": "full" | "db_only", "note": "string <= 200 karakter" }
```

| HTTP | Body | Arti |
|---|---|---|
| 201 | baris `backup_jobs` yang baru dibuat | Berhasil |
| 401 | `{"error":"unauthorized"}` | Token tidak ada/tidak valid |
| 403 | `{"error":"forbidden"}` | Bukan admin |
| 409 | `{"error":"Masih ada backup yang berjalan"}` | Sudah ada job aktif |
| 500 | `{"error":"<pesan>"}` | Kesalahan server |

### 9.3 Pemetaan error di Flutter

`FunctionException.status` → 401: sesi habis · 403: tanpa akses · 409: sudah berjalan · lainnya/jaringan: pesan umum + opsi coba lagi.

## 10. Implementasi Flutter (acuan)

Gunakan pola state management yang sudah dipakai proyek (Riverpod/Bloc/Provider). Berikut bentuk minimal.

**Model**
```dart
class BackupJob {
  final String id;
  final String status;       // pending | running | success | failed
  final String triggerType;  // scheduled | manual
  final String scope;        // full | db_only
  final String? note;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? sizeBytes;
  final String? location;
  final String? error;

  const BackupJob({
    required this.id, required this.status, required this.triggerType,
    required this.scope, required this.createdAt,
    this.note, this.startedAt, this.finishedAt,
    this.sizeBytes, this.location, this.error,
  });

  factory BackupJob.fromMap(Map<String, dynamic> m) => BackupJob(
        id: m['id'] as String,
        status: m['status'] as String,
        triggerType: m['trigger_type'] as String,
        scope: m['scope'] as String,
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        startedAt: m['started_at'] == null
            ? null : DateTime.parse(m['started_at'] as String).toLocal(),
        finishedAt: m['finished_at'] == null
            ? null : DateTime.parse(m['finished_at'] as String).toLocal(),
        sizeBytes: (m['size_bytes'] as num?)?.toInt(),
        location: m['location'] as String?,
        error: m['error'] as String?,
      );

  bool get isActive => status == 'pending' || status == 'running';
  Duration? get duration => (startedAt != null && finishedAt != null)
      ? finishedAt!.difference(startedAt!) : null;
}
```

**Repository**
```dart
class BackupRepository {
  BackupRepository(this._client);
  final SupabaseClient _client;

  Stream<List<BackupJob>> watchRecent() => _client
      .from('backup_jobs')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(10)
      .map((rows) => rows.map(BackupJob.fromMap).toList());

  Future<BackupJob?> lastSuccess() async {
    final row = await _client
        .from('backup_jobs')
        .select()
        .eq('status', 'success')
        .order('finished_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : BackupJob.fromMap(row);
  }

  Future<BackupJob> request({required String scope, String? note}) async {
    final res = await _client.functions.invoke('request-backup', body: {
      'scope': scope,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return BackupJob.fromMap(Map<String, dynamic>.from(res.data as Map));
  }
}
```

**Dialog "Backup sekarang"**
```dart
Future<void> requestBackup(BuildContext context, BackupRepository repo) async {
  var scope = 'full';
  final noteCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Backup sekarang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'full', label: Text('Lengkap')),
                ButtonSegment(value: 'db_only', label: Text('Database saja')),
              ],
              selected: {scope},
              onSelectionChanged: (s) => setState(() => scope = s.first),
            ),
            if (scope == 'db_only')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Storage tidak diperbarui. Salinan storage tetap dari backup lengkap terakhir.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mulai')),
        ],
      ),
    ),
  );
  if (ok != true) return;

  try {
    await repo.request(scope: scope, note: noteCtrl.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Job dibuat. Worker mengambilnya dalam ±1 menit.')));
    }
  } on FunctionException catch (e) {
    final msg = switch (e.status) {
      401 => 'Sesi berakhir, silakan login ulang',
      403 => 'Anda tidak punya akses untuk fitur ini',
      409 => 'Masih ada backup yang berjalan',
      _ => 'Gagal memulai backup. Coba lagi.',
    };
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memulai backup. Coba lagi.')));
    }
  }
}
```

## 11. Prasyarat backend Supabase (kerjakan sebelum Flutter)

Urutan: (1) migrasi SQL → (2) jadikan user admin → (3) deploy Edge Function → (4) jadwal `pg_cron`.

### 11.1 Migrasi SQL

```sql
create table public.backup_jobs (
  id            uuid primary key default gen_random_uuid(),
  status        text not null default 'pending'
                check (status in ('pending','running','success','failed')),
  trigger_type  text not null default 'scheduled'
                check (trigger_type in ('scheduled','manual')),
  scope         text not null default 'full'
                check (scope in ('full','db_only')),
  note          text,
  requested_by  uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  started_at    timestamptz,
  finished_at   timestamptz,
  size_bytes    bigint,
  location      text,
  error         text
);

-- Hanya satu job aktif pada satu waktu
create unique index backup_jobs_one_active
  on public.backup_jobs ((true))
  where status in ('pending','running');

alter table public.backup_jobs enable row level security;

-- Admin hanya boleh membaca. Penulisan dilakukan Edge Function (service role)
-- dan worker (koneksi Postgres), keduanya melewati RLS.
create policy "admin can read backup_jobs"
  on public.backup_jobs for select
  to authenticated
  using ((select public.is_admin()));

alter publication supabase_realtime add table public.backup_jobs;
```

### 11.2 Menjadikan user admin

Role otorisasi disimpan di `profiles.role`. Migration `20261021040000_backup_profile_admin_authorization.sql` mencegah anggota mengubah role sendiri, dan RLS memakai helper `public.is_admin()`.
```sql
update auth.users
set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'
where email = 'admin@contoh.com';
```
User harus login ulang agar JWT memuat role baru.

### 11.3 Edge Function

```bash
supabase functions new request-backup
```

`supabase/functions/request-backup/index.ts`:
```ts
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "unauthorized" }, 401);

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) return json({ error: "unauthorized" }, 401);
  const adminClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: profile, error: profileError } = await adminClient
    .from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (profileError) return json({ error: "authorization_check_failed" }, 500);
  if (profile?.role !== "admin") return json({ error: "forbidden" }, 403);

  const body = await req.json().catch(() => ({}));
  const scope = body.scope === "db_only" ? "db_only" : "full";
  const note = typeof body.note === "string" ? body.note.slice(0, 200) : null;

  const { data, error: insErr } = await adminClient
    .from("backup_jobs")
    .insert({ requested_by: user.id, trigger_type: "manual", scope, note })
    .select()
    .single();

  if (insErr) {
    if (insErr.code === "23505") return json({ error: "Masih ada backup yang berjalan" }, 409);
    return json({ error: insErr.message }, 500);
  }
  return json(data, 201);
});
```
Deploy: `supabase functions deploy request-backup` (verifikasi JWT bawaan tetap aktif).

### 11.4 Jadwal bulanan (`pg_cron`)

`pg_cron` berjalan dalam UTC. 02:00 WIB tanggal 1 sama dengan 19:00 UTC pada hari **sebelumnya**, sehingga jadwal dibuat harian dan disaring berdasarkan tanggal WIB:

```sql
select cron.schedule('monthly-backup', '0 19 * * *', $$
  insert into public.backup_jobs (trigger_type, scope)
  select 'scheduled', 'full'
  where extract(day from (now() at time zone 'Asia/Jakarta')) = 1
  on conflict do nothing
$$);
```
Jika sebelumnya sudah ada jadwal lama, hapus dahulu: `select cron.unschedule('<nama-jadwal-lama>');`.

## 12. Non-fungsional

- **Keamanan:** tidak ada `service_role`, password Postgres, atau kunci S3 di kode/aset aplikasi. Penegakan admin di tiga lapis: UI (FR-1), RLS (select), Edge Function (insert).
- **Ketahanan:** aplikasi boleh ditutup kapan saja. Backup tetap berjalan di server.
- **Performa:** daftar riwayat dibatasi 10 item. Query banner memakai limit 1.
- **Lokalisasi:** semua teks Bahasa Indonesia, waktu mengikuti zona waktu perangkat.
- **Kompatibilitas:** memakai versi `supabase_flutter` yang sudah ada di proyek. Cek bahwa `.stream()` dan `functions.invoke` tersedia di versi tersebut.

## 13. Rencana kerja

- [ ] 1. Jalankan migrasi SQL (11.1) di project Supabase
- [ ] 2. Set akun admin (11.2), login ulang di aplikasi
- [ ] 3. Deploy Edge Function (11.3)
- [ ] 4. Buat jadwal bulanan (11.4)
- [ ] 5. Flutter: model `BackupJob` dan `BackupRepository`
- [ ] 6. Flutter: halaman Backup (banner, tombol, riwayat, state loading/kosong/error)
- [ ] 7. Flutter: dialog "Backup sekarang" dan penanganan error
- [ ] 8. Flutter: halaman/bottom sheet detail job
- [ ] 9. Fallback polling saat stream error (FR-7)
- [ ] 10. Uji end-to-end bersama worker (bagian 14)

## 14. Skenario uji penerimaan

1. Login admin → menu Backup tampil. Login non-admin → menu tidak tampil dan pemanggilan langsung ke function mendapat 403.
2. Tekan "Backup sekarang" (Lengkap) → baris `pending` muncul < 2 detik, lalu menjadi `running` ≤ 1 menit, lalu `success`.
3. Saat job aktif, tombol nonaktif. Pemanggilan paksa ke function membalas 409 dan aplikasi menampilkan pesan yang benar.
4. Pilih "Database saja" → job selesai tanpa menyalin storage (cek di sisi worker).
5. Salahkan password database di worker sementara → job `failed`, pesan error tampil di riwayat dan detail.
6. Tidak ada job sukses sama sekali → banner error. Job sukses terakhir > 35 hari → banner peringatan.
7. Matikan koneksi internet perangkat sesaat saat stream aktif → aplikasi pulih sendiri (stream tersambung kembali atau fallback polling).
8. Non-admin yang membaca tabel lewat API langsung mendapat 0 baris.

## 15. Asumsi dan pertanyaan terbuka

- Admin ditentukan lewat `profiles.role = 'admin'`. Jalankan migration otorisasi lanjutan dan deploy ulang Edge Function setelah menerapkan perubahan ini.
- Plan Supabase (Free/Pro) memengaruhi kuota egress dan auto-pause. Lihat bagian "Biaya" di `worker/PRD.md`.
- Pembatalan job (`cancelled`) dan tombol unduh backup ditunda ke versi berikutnya.
