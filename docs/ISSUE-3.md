# ISSUE-3: Kocokan Arisan — Perbaikan & Penguatan Fitur Core

**Status:** Implementation Complete — Pending Deploy & E2E Verification  
**Scope:** Fitur kocokan digital (`lib/features/draw/`) — perbaikan bug kritis, validasi bisnis, revamp UI/UX, dan Supabase RPC.  
**Terkait:** `PRD.md`, `DATABASE_SCHEMA.md`, `ARCHITECTURE.md`, `DESIGN.md`, `COMPONENTS.md`

---

## 1. Panduan Eksekusi & Standar Kualitas (Wajib Dipatuhi)

1. **Wajib Memanfaatkan Skills Project**:
   - Arsitektur & State Management: `flutter-apply-architecture-best-practices`
   - Testing: `flutter-add-widget-test`
   - UI & Layout: `flutter-build-responsive-layout`, `frontend-design`
   - Supabase: `supabase`, `supabase-postgres-best-practices`
   - Animasi: `flutter-animations`
2. **Prinsip Test-Driven Development (TDD)**:
   - Buat test **sebelum** implementasi perubahan repository, controller, atau screen.
   - Cakup: success state, error state, validasi blocked (belum semua bayar, bukan hari-H), dan winner reveal.
3. **Standar Zero Error**:
   - Semua test wajib pass (`flutter test`).
   - Kode wajib lolos linter tanpa error atau warning (`flutter analyze`).
   - Setelah seluruh verifikasi lolos, checklist di bagian akhir dokumen ini wajib diupdate.

---

## 2. Gap Analysis — Apa yang Sudah Ada vs Apa yang Harus Diperbaiki

### Sudah Ada (Partial)

| Komponen | File | Kondisi |
|---|---|---|
| DrawModel & DrawHistoryModel | `lib/features/draw/domain/draw_model.dart` | Ada, tapi perlu field winner (nested MemberModel) |
| DrawRepository | `lib/features/draw/data/draw_repository.dart` | **Bug kritis**: query ke tabel salah (`members` → `profiles`, `periods` → `arisan_periods`) |
| DrawController | `lib/features/draw/presentation/controllers/draw_controller.dart` | Ada, minimalis — perlu validasi guard |
| DrawScreen | `lib/features/draw/presentation/screens/draw_screen.dart` | Ada, basic — tidak ada validasi, tidak ada animasi |
| WinnerRevealDialog | `lib/features/draw/presentation/widgets/winner_reveal_dialog.dart` | **Bug**: nama pemenang hardcoded "Memuat nama..." |
| DrawCandidateTile | `lib/features/draw/presentation/widgets/draw_candidate_tile.dart` | OK, bisa dipertahankan |
| DrawHistoryList | `lib/features/draw/presentation/widgets/draw_history_list.dart` | OK, bisa dipertahankan |
| draw_providers.dart | `lib/features/draw/presentation/providers/draw_providers.dart` | Ada, perlu tambah provider validasi |
| Edge Function `run-draw` | `supabase/functions/run-draw/index.ts` | Ada, tapi memanggil RPC `run_draw` yang **belum ada** di DB |
| RPC `run_draw` | (migration) | **Tidak ada** — harus dibuat |

### Harus Ditambah / Diperbaiki

| # | Apa | Mengapa | Status |
|---|---|---|---|
| 1 | Buat SQL migration untuk RPC `run_draw` | Edge Function memanggil RPC ini — saat ini akan error 404 | ✅ Done |
| 2 | Fix tabel names di `DrawRepository` | `members` & `periods` tidak ada, crash saat runtime | ✅ Done |
| 3 | Tambah `allMembersPaidProvider` | Validasi 100% iuran lunas sebelum kocokan | ✅ Done |
| 4 | Tambah `isDrawDayProvider` | Validasi event_date == tanggal hari ini | ✅ Done |
| 5 | Guard di DrawController sebelum `runDraw()` | Block kocokan jika validasi gagal, tampilkan pesan jelas | ✅ Done |
| 6 | Fix WinnerRevealDialog | Fetch nama + avatar pemenang dari members, tampilkan nominal iuran | ✅ Done |
| 7 | Revamp DrawScreen UI/UX | Full-screen experience, animasi countdown, suspense — sesuai DESIGN.md §12 | ✅ Done |
| 8 | Tambah `DrawAnimationScreen` | Layar dedicated saat animasi kocokan berjalan | ✅ Done |
| 9 | Update DrawModel | Tambah field `winnerName`, `totalAmount` dari response Edge Function | ✅ Done |
| 10 | Edge Function: validasi all-paid server-side | Double check di server, bukan hanya client | ✅ Done |
| 11 | Test suite draw feature | Unit + widget test | ✅ Done (17 tests) |

---

## 3. Aturan Bisnis (Business Rules)

Kocokan **hanya bisa dijalankan** jika **semua kondisi** berikut terpenuhi:

```
1. User adalah admin (role = 'admin')
2. Ada periode aktif (status = 'upcoming' atau 'ongoing') 
3. event_date periode == tanggal hari ini (yyyy-MM-dd)
4. Semua anggota aktif di periode ini sudah berstatus 'paid'
5. Periode ini belum pernah di-draw (draws.period_id belum ada)
```

Jika salah satu kondisi tidak terpenuhi, tombol "Mulai Kocokan" **disabled** dengan pesan spesifik per kondisi.

---

## 4. Perubahan Database

### 4.1 Migrasi Baru: `011_run_draw_rpc.sql`

Buat file `supabase/migrations/011_run_draw_rpc.sql`:

```sql
-- RPC: run_draw
-- Dipanggil dari Edge Function run-draw (bukan langsung dari client)
-- Menjalankan kocokan: pilih pemenang acak dari kandidat eligible,
-- simpan ke draws, update arisan_periods.winner_id, buat periode berikutnya.
-- Idempoten: jika draw sudah ada untuk period_id ini, kembalikan data draw yang ada.

create or replace function run_draw(p_period_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw_id        uuid;
  v_winner_id      uuid;
  v_period_number  integer;
  v_contribution   numeric;
  v_eligible_ids   uuid[];
  v_past_winners   uuid[];
  v_active_members uuid[];
  v_next_period_number integer;
  v_next_event_date    date;
  v_winner_name    text;
  v_total_collected numeric;
begin
  -- 1. Cek idempoten: draw sudah ada untuk periode ini?
  select id into v_draw_id
  from draws
  where period_id = p_period_id;

  if v_draw_id is not null then
    -- Kembalikan data draw yang sudah ada
    select row_to_json(d)
    into strict v_draw_id
    from (
      select dr.id, dr.period_id, dr.winner_id, dr.conducted_at as created_at,
             p.full_name as winner_name
      from draws dr
      join profiles p on p.id = dr.winner_id
      where dr.id = v_draw_id
    ) d;
    return v_draw_id::json;
  end if;

  -- 2. Ambil data periode
  select period_number, contribution_amount
  into v_period_number, v_contribution
  from arisan_periods
  where id = p_period_id;

  if not found then
    raise exception 'Periode tidak ditemukan: %', p_period_id;
  end if;

  -- 3. Hitung total terkumpul
  select coalesce(sum(amount), 0)
  into v_total_collected
  from payments
  where period_id = p_period_id and status = 'paid';

  -- 4. Ambil semua anggota aktif
  select array_agg(id) into v_active_members
  from profiles
  where is_active = true;

  -- 5. Ambil pemenang sebelumnya
  select array_agg(winner_id) into v_past_winners
  from arisan_periods
  where winner_id is not null;

  -- 6. Tentukan kandidat eligible (exclude past winners, kecuali semua sudah menang)
  if v_past_winners is null then
    v_eligible_ids := v_active_members;
  elsif (select count(*) from unnest(v_active_members) m
         where m = any(v_past_winners)) >= array_length(v_active_members, 1) then
    -- Semua sudah pernah menang: reset siklus
    v_eligible_ids := v_active_members;
  else
    select array_agg(m) into v_eligible_ids
    from unnest(v_active_members) m
    where m <> all(v_past_winners);
  end if;

  if v_eligible_ids is null or array_length(v_eligible_ids, 1) = 0 then
    raise exception 'Tidak ada kandidat eligible untuk kocokan.';
  end if;

  -- 7. Pilih pemenang secara acak
  select v_eligible_ids[1 + floor(random() * array_length(v_eligible_ids, 1))::int]
  into v_winner_id;

  -- 8. Simpan draw
  insert into draws (period_id, eligible_member_ids, winner_id, draw_method, conducted_by, conducted_at)
  values (
    p_period_id,
    v_eligible_ids,
    v_winner_id,
    'random',
    auth.uid(),
    now()
  )
  returning id into v_draw_id;

  -- 9. Update winner_id dan total_collected di periode ini
  update arisan_periods
  set winner_id = v_winner_id,
      total_collected = v_total_collected,
      status = 'completed'
  where id = p_period_id;

  -- 10. Update has_won_before di profiles
  update profiles
  set has_won_before = true
  where id = v_winner_id;

  -- 11. Buat periode berikutnya (2 bulan setelah event_date)
  v_next_period_number := v_period_number + 1;
  select event_date + interval '2 months' into v_next_event_date
  from arisan_periods where id = p_period_id;

  insert into arisan_periods (period_number, event_date, host_id, status)
  values (v_next_period_number, v_next_event_date, v_winner_id, 'upcoming')
  on conflict do nothing;

  -- 12. Ambil nama pemenang
  select full_name into v_winner_name from profiles where id = v_winner_id;

  -- 13. Return result
  return json_build_object(
    'id', v_draw_id,
    'period_id', p_period_id,
    'winner_id', v_winner_id,
    'winner_name', v_winner_name,
    'total_collected', v_total_collected,
    'created_at', now()
  );
end;
$$;

-- Grant execute hanya ke service_role (dipanggil via Edge Function)
revoke execute on function run_draw(uuid) from public;
revoke execute on function run_draw(uuid) from authenticated;
grant execute on function run_draw(uuid) to service_role;
```

### 4.2 Update Edge Function: Validasi All-Paid Server-Side

Edit `supabase/functions/run-draw/index.ts` — tambahkan pengecekan semua anggota aktif sudah paid sebelum memanggil RPC:

```typescript
// Setelah validasi admin, sebelum memanggil run_draw:
const { count: unpaidCount } = await supabaseAdmin
  .from('payments')
  .select('*', { count: 'exact', head: true })
  .eq('period_id', periodId)
  .eq('status', 'unpaid');

const { count: activeCount } = await supabaseAdmin
  .from('profiles')
  .select('*', { count: 'exact', head: true })
  .eq('is_active', true);

const { count: paidCount } = await supabaseAdmin
  .from('payments')
  .select('*', { count: 'exact', head: true })
  .eq('period_id', periodId)
  .eq('status', 'paid');

if (paidCount < activeCount) {
  throw new Error(`Belum semua anggota membayar iuran. ${paidCount}/${activeCount} sudah bayar.`);
}
```

---

## 5. Perubahan Flutter — Domain & Data Layer

### 5.1 Update `DrawModel`

Tambah field `winnerName` dan `totalCollected` karena Edge Function kini mengembalikannya:

```dart
// lib/features/draw/domain/draw_model.dart
@freezed
class DrawModel with _$DrawModel {
  const factory DrawModel({
    required String id,
    required String periodId,
    required String winnerId,
    required DateTime createdAt,
    String? winnerName,      // NEW: dari Edge Function response
    double? totalCollected,  // NEW: total iuran yang terkumpul
  }) = _DrawModel;

  factory DrawModel.fromJson(Map<String, dynamic> json) =>
      _$DrawModelFromJson(json);
}
```

### 5.2 Fix `DrawRepository`

Perbaiki nama tabel dan join:

```dart
// lib/features/draw/data/draw_repository.dart

// getCandidates: ganti 'members' → 'profiles', 'periods' → 'arisan_periods'
Future<List<MemberModel>> getCandidates(String periodId) async {
  final activeMembersResp = await _client
      .from('profiles')           // FIX: 'members' → 'profiles'
      .select('*')
      .eq('is_active', true);

  final pastWinnersResp = await _client
      .from('arisan_periods')     // FIX: 'periods' → 'arisan_periods'
      .select('winner_id')
      .not('winner_id', 'is', null);
  // ... rest of logic sama
}

// getDrawHistory: fix join ke arisan_periods dan profiles
Future<List<DrawHistoryModel>> getDrawHistory() async {
  final response = await _client
      .from('draws')
      .select('''
        id,
        period_id,
        winner_id,
        conducted_at,
        arisan_periods!inner(period_number),
        winner:profiles!winner_id(full_name, photo_url)
      ''')                       // FIX: join ke arisan_periods & profiles
      .order('conducted_at', ascending: false);
  // ... parse dengan field baru (conducted_at bukan created_at)
}

// watchDrawHistory: fix stream — tidak support join, gunakan FutureProvider polling
// ATAU gunakan stream sederhana lalu re-fetch dengan getDrawHistory()
```

### 5.3 Tambah Provider Validasi

Di `lib/features/draw/presentation/providers/draw_providers.dart`:

```dart
/// True jika semua anggota aktif di periode aktif sudah berstatus 'paid'
final allMembersPaidProvider = FutureProvider<bool>((ref) async {
  final paymentStatuses = await ref.watch(memberPaymentStatusListProvider.future);
  if (paymentStatuses.isEmpty) return false;
  return paymentStatuses.every((s) => s.status == 'paid');
});

/// True jika event_date periode aktif == tanggal hari ini
final isDrawDayProvider = Provider<bool>((ref) {
  final period = ref.watch(activePeriodProvider).valueOrNull;
  if (period == null) return false;
  final today = DateTime.now();
  final eventDate = period.eventDate;
  return eventDate.year == today.year &&
      eventDate.month == today.month &&
      eventDate.day == today.day;
});

/// True jika periode ini belum pernah di-draw
final isDrawAlreadyDoneProvider = FutureProvider<bool>((ref) async {
  final period = ref.watch(activePeriodProvider).valueOrNull;
  if (period == null) return false;
  return period.winnerId != null;
});
```

### 5.4 Update `DrawController`

Tambah guard validasi sebelum `runDraw()`:

```dart
// lib/features/draw/presentation/controllers/draw_controller.dart
Future<void> runDraw(String periodId) async {
  // Guard: validasi semua kondisi
  final allPaid = await ref.read(allMembersPaidProvider.future);
  if (!allPaid) {
    state = AsyncError('Belum semua anggota membayar iuran.', StackTrace.current);
    return;
  }
  final isDrawDay = ref.read(isDrawDayProvider);
  if (!isDrawDay) {
    state = AsyncError('Kocokan hanya bisa dijalankan pada hari-H acara.', StackTrace.current);
    return;
  }

  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final repo = ref.read(drawRepositoryProvider);
    return repo.runDraw(periodId);
  });
}
```

---

## 6. Perubahan Flutter — Presentation Layer (UI/UX Revamp)

### 6.1 DrawScreen — Revamp Total

Sesuai `DESIGN.md §12 — Digital Kocokan`. Screen harus menampilkan:

**Bagian Persiapan (sebelum kocokan dimulai):**

```
┌─────────────────────────────────┐
│  🎰 Kocokan Arisan              │
│     Periode #9                  │
├─────────────────────────────────┤
│                                 │
│  ⚠️ STATUS VALIDASI             │
│  ✅ Semua iuran lunas (17/17)   │
│  ✅ Hari ini adalah hari acara  │
│  ✅ Belum pernah dikocok        │
│                                 │
├─────────────────────────────────┤
│  KANDIDAT (14 orang)            │
│  ┌──────────────────────────┐   │
│  │ 👤 Budi Rasijan           │   │
│  │ 👤 Ahmad Rasijan          │   │
│  │ 👤 Siti Rasijan           │   │
│  │ ...                      │   │
│  └──────────────────────────┘   │
│                                 │
│  ℹ️ 3 anggota dikecualikan      │
│     (sudah pernah menang)       │
│                                 │
│  ┌──────────────────────────┐   │
│  │   🎲 MULAI KOCOKAN       │   │   ← disabled jika validasi gagal
│  └──────────────────────────┘   │
│                                 │
│  RIWAYAT PEMENANG               │
│  • #8 — Ahmad Rasijan           │
│  • #7 — Siti Rasijan            │
└─────────────────────────────────┘
```

**Bagian Animasi (DrawAnimationScreen — full screen):**

```
┌─────────────────────────────────┐
│                                 │
│           MENGOCOK...           │
│                                 │
│         ┌──────────┐            │
│         │  👤 ???  │            │  ← nama berputar cepat
│         └──────────┘            │
│                                 │
│    ●●●●●●●●●●●●●●●●●            │  ← progress bar animasi
│                                 │
│      3... 2... 1...             │  ← countdown
│                                 │
└─────────────────────────────────┘
```

**Winner Reveal (WinnerRevealDialog — redesign):**

```
┌─────────────────────────────────┐
│                                 │
│  🎉  SELAMAT!  🎉               │
│                                 │
│        ┌──────────┐             │
│        │  AVATAR  │             │
│        └──────────┘             │
│                                 │
│     BUDI RASIJAN                │  ← nama besar, bold
│     Pemenang Periode #9         │
│                                 │
│     Rp8.500.000                 │  ← total terkumpul
│                                 │
│  🏠 Tuan Rumah Berikutnya       │
│     Periode #10                 │
│                                 │
│  [         Tutup        ]       │
└─────────────────────────────────┘
```

### 6.2 Komponen Baru yang Dibuat

| Komponen | File | Deskripsi |
|---|---|---|
| `DrawValidationCard` | `draw/presentation/widgets/draw_validation_card.dart` | Card status validasi dengan ikon ✅/❌ per syarat |
| `DrawAnimationScreen` | `draw/presentation/screens/draw_animation_screen.dart` | Full-screen animasi kocokan dengan countdown & nama berputar |
| `DrawCandidateChip` | `draw/presentation/widgets/draw_candidate_chip.dart` | Chip compact untuk grid kandidat (alternatif tile untuk banyak anggota) |

### 6.3 Warna & Animasi

Gunakan token yang sudah ada (`AppColors`, `AppSpacing`, `AppTypography`, `AppMotion`):

- Background animasi: `AppColors.primary` (emerald gradient)
- Nama pemenang: `AppColors.accent` (warm gold)
- Animasi: `TweenAnimationBuilder`, `AnimationController` dengan `Curves.elasticOut`
- Transisi DrawScreen → DrawAnimationScreen: `PageRouteBuilder` dengan fade + slide up
- Confetti / partikel di WinnerRevealDialog: custom `CustomPainter` atau package `confetti`

---

## 7. Alur Lengkap Fitur Kocokan

```
[Admin buka DrawScreen]
         │
         ▼
[Load: candidates, payment status, period info]
         │
         ▼
[Tampilkan ValidationCard: semua syarat]
         │
    semua ✅?
    ┌─── YES ──→ [Tombol "Mulai Kocokan" ENABLED]
    └─── NO  ──→ [Tombol DISABLED, pesan spesifik per syarat]
         │
[Admin tap "Mulai Kocokan"]
         │
         ▼
[ConfirmationBottomSheet — desain modern]
         │
[Admin konfirmasi]
         │
         ▼
[Navigator push DrawAnimationScreen (full-screen)]
         │
[Animasi: nama berputar 3 detik + countdown]
         │ (sambil Edge Function run-draw dipanggil)
         │
         ▼
[Server: validasi admin, all-paid, run_draw RPC]
         │
         ▼
[Realtime broadcast via draws table insert]
         │
         ▼
[DrawAnimationScreen animasi slow down → stop]
         │
         ▼
[WinnerRevealDialog: nama + avatar + total + next period info]
         │
[Admin tap Tutup → kembali ke DrawScreen → refresh history]
```

---

## 8. Supabase Realtime

Pertahankan `drawHistoryStreamProvider` yang sudah ada. Tambahkan:

```dart
/// Stream untuk mendeteksi kapan draw baru muncul di tabel 'draws'
final drawInsertStreamProvider = StreamProvider.family<void, String>((ref, periodId) {
  final client = ref.watch(_supabase);
  return client
      .from('draws')
      .stream(primaryKey: ['id'])
      .eq('period_id', periodId)
      .map((_) {}); // hanya trigger rebuild
});
```

Gunakan di `DrawAnimationScreen` untuk mendeteksi kapan Edge Function selesai & otomatis tampilkan `WinnerRevealDialog`.

---

## 9. File yang Dimodifikasi / Dibuat

### Supabase
- 🆕 `supabase/migrations/011_run_draw_rpc.sql` — RPC `run_draw`
- ✏️ `supabase/functions/run-draw/index.ts` — tambah validasi all-paid server-side

### Flutter — Domain
- ✏️ `lib/features/draw/domain/draw_model.dart` — tambah `winnerName`, `totalCollected`

### Flutter — Data
- ✏️ `lib/features/draw/data/draw_repository.dart` — fix tabel names, fix join query

### Flutter — Presentation
- ✏️ `lib/features/draw/presentation/providers/draw_providers.dart` — tambah `allMembersPaidProvider`, `isDrawDayProvider`, `isDrawAlreadyDoneProvider`
- ✏️ `lib/features/draw/presentation/controllers/draw_controller.dart` — tambah validasi guard
- ✏️ `lib/features/draw/presentation/screens/draw_screen.dart` — revamp total UI/UX
- 🆕 `lib/features/draw/presentation/screens/draw_animation_screen.dart` — full-screen animasi
- 🆕 `lib/features/draw/presentation/widgets/draw_validation_card.dart` — status validasi
- 🆕 `lib/features/draw/presentation/widgets/draw_candidate_chip.dart` — chip kandidat kompak
- ✏️ `lib/features/draw/presentation/widgets/winner_reveal_dialog.dart` — fix nama + redesign

### Tests
- 🆕 `test/features/draw/data/draw_repository_test.dart`
- 🆕 `test/features/draw/presentation/controllers/draw_controller_test.dart`
- 🆕 `test/features/draw/presentation/screens/draw_screen_test.dart`

---

## 10. Verifikasi & Testing

### A. Database
- [x] Jalankan migration `011_run_draw_rpc.sql` di Supabase
- [ ] Test RPC `run_draw` langsung via Supabase SQL Editor dengan period_id yang valid
- [ ] Pastikan RLS tidak memblokir service_role (grant sudah benar)
- [ ] Verifikasi idempoten: panggil `run_draw` dua kali dengan period_id sama → hasil sama, tidak insert 2x

### B. Edge Function
- [ ] Deploy ulang `run-draw` dengan validasi all-paid baru
- [ ] Test via Supabase Dashboard → Edge Functions → invoke manual
- [ ] Pastikan error message yang dikembalikan user-friendly

### C. Regresi — Fitur Lain
- [ ] `flutter test` semua test lama tetap pass (khususnya payments, periods, auth)
- [ ] `flutter analyze` zero errors
- [ ] Navigasi dari HomeScreen → DrawScreen tetap berfungsi
- [ ] activePeriodProvider masih reaktif setelah draw selesai (periode baru muncul)
- [ ] Histori di HistoryScreen menampilkan pemenang baru

### D. Draw Feature End-to-End
- [ ] Admin buka DrawScreen → kandidat tampil benar (profiles, exclude past winners)
- [ ] ValidationCard menampilkan ❌ jika ada iuran belum lunas
- [ ] ValidationCard menampilkan ❌ jika bukan hari-H
- [ ] Tombol disabled dengan pesan yang jelas saat syarat belum terpenuhi
- [ ] Ketika semua syarat ✅ → tombol aktif → konfirmasi → animasi → winner reveal
- [ ] WinnerRevealDialog menampilkan nama pemenang, avatar, total iuran, info periode berikutnya
- [ ] Setelah tutup → DrawHistoryList menampilkan pemenang baru
- [ ] Supabase Realtime: device lain yang buka DrawScreen otomatis update history
- [ ] Periode baru (host = pemenang) sudah muncul di activePeriodProvider

---

## 11. Checklist Implementasi

### A. Database

- [x] Buat `supabase/migrations/011_run_draw_rpc.sql` dengan RPC `run_draw`
- [x] Jalankan migration di Supabase project
- [ ] Verifikasi grant permission hanya untuk service_role
- [ ] Test idempoten RPC

### B. Edge Function

- [x] Tambah validasi all-paid di `supabase/functions/run-draw/index.ts`
- [ ] Deploy ulang Edge Function
- [ ] Test manual via Supabase Dashboard

### C. Flutter — Domain & Data

- [x] Update `DrawModel` (tambah `winnerName`, `totalCollected`)
- [x] Regenerasi freezed: `dart run build_runner build`
- [x] Fix `DrawRepository.getCandidates()` — tabel `profiles` & `arisan_periods`
- [x] Fix `DrawRepository.getDrawHistory()` — join ke `arisan_periods` & `profiles`
- [x] Fix `DrawRepository.watchDrawHistory()` — sesuaikan field names

### D. Flutter — State Management

- [x] Tambah `allMembersPaidProvider` di `draw_providers.dart`
- [x] Tambah `isDrawDayProvider` di `draw_providers.dart`
- [x] Tambah `isDrawAlreadyDoneProvider` di `draw_providers.dart`
- [x] Tambah guard validasi di `DrawController.runDraw()`

### E. Flutter — UI/UX

- [x] Buat `DrawValidationCard` widget
- [x] Buat `DrawAnimationScreen` dengan animasi nama berputar & countdown
- [x] Revamp `DrawScreen` — ValidationCard, kandidat grid, tombol adaptif
- [x] Fix & redesign `WinnerRevealDialog` — tampilkan nama, avatar, total, info next period
- [x] Buat `DrawCandidateChip` untuk tampilan kandidat lebih kompak
- [x] Pastikan semua warna pakai `AppColors.*`, teks pakai `AppTypography.*`

### F. Testing & Verifikasi

- [x] Buat `test/features/draw/data/draw_repository_test.dart`
- [x] Buat `test/features/draw/presentation/controllers/draw_controller_test.dart`
- [x] Buat `test/features/draw/presentation/screens/draw_screen_test.dart`
- [x] Jalankan `flutter test` — semua pass (17/17)
- [x] Jalankan `flutter analyze` — zero errors/warnings
- [ ] Uji end-to-end di device/emulator dengan skenario lengkap

### G. Setelah Selesai

- [ ] Update `docs/issue.md` bagian "6. Kocokan digital" → status & checklist diperbarui
- [x] Update checklist di dokumen ini (ISSUE-3.md)
