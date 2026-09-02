# BANI RASIJAN — Design Specification

**Tagline:** Arisan Keluarga  
**Platform:** Flutter — Android & iOS  
**Design Version:** 2.0

## 1. Brand Identity

### Brand
**BANI RASIJAN**

### Tagline
**Arisan Keluarga**

Recommended lockup:

```text
BANI RASIJAN
Arisan Keluarga
```

The family name is the primary brand. The product should feel like a **digital home for the family**, not a banking, fintech, accounting, or generic lottery application.

### Personality
- Warm
- Trusted
- Modern
- Family-oriented
- Simple
- Transparent
- Elegant
- Approachable

## 2. Design Principles

### Family First
Visual hierarchy:

```text
Family → Gathering → Arisan → Transparency → Financial Tracking
```

### Transparency
Users should quickly understand:
- Next arisan date and host
- Payment status
- Collected amount
- Winner
- Gathering fund balance
- Voting progress

### Simple for All Ages
Because users span ages, including seniors:
- Body text preferably 15–16px
- Touch targets around 44–48px
- Clear labels
- Strong contrast
- Important actions use icon + text
- Avoid hidden gestures and dense tables

### Event Mode
Screens used during gatherings must be readable quickly:
- Agenda
- Kocokan
- Winner Result
- Payment Summary
- Gathering Voting

## 3. Visual Direction

**Modern Family Minimalism**

Use clean layouts, whitespace, soft cards, clear hierarchy, warm photography, restrained colors, and subtle motion.

Avoid banking-style UI, excessive gradients, heavy shadows, dense spreadsheets, excessive gold, and generic dashboard templates.

## 4. Color System

### Primary
```text
Primary       #0F766E
Primary Dark  #115E59
```

### Accent
```text
Warm Gold     #D99A2B
Orange        #ff914d
```

Use gold mainly for winners, celebrations, achievements, and special highlights.

### Neutral
```text
Background     #F8FAFC
Surface        #FFFFFF
Text Primary   #17202A
Text Secondary #64748B
Divider        #E5E7EB
```

### Semantic
```text
Success        #16A34A
Warning        #F59E0B
Error          #DC2626
Info           #2563EB
```

Recommended visual ratio:
- 60% white/background
- 30% emerald
- 10% gold/semantic accents

## 5. Typography

Primary font: **Plus Jakarta Sans**  
Fallback: **Inter / system sans-serif**

| Style | Size | Weight |
|---|---:|---|
| Display | 32px | Bold |
| H1 | 24px | Bold |
| H2 | 20px | SemiBold |
| H3 | 18px | SemiBold |
| Body Large | 16px | Regular |
| Body | 15px | Regular |
| Body Medium | 15px | Medium |
| Caption | 13px | Regular |
| Button | 15px | SemiBold |

Avoid body text below 14px.

## 6. Spacing

Use a 4px base grid:

```text
4  8  12  16  20  24  32  40  48
```

Default horizontal screen padding: **16px**.

## 7. Shape & Elevation

```text
Small control  8px
Input          10–12px
Button         12px
Card           16px
Hero           20px
Sheet          20–24px
```

Cards use white surface, subtle `#E5E7EB` border, and minimal elevation.

## 8. Navigation

Primary bottom navigation:

```text
Beranda | Iuran | Arisan | Profil
```

Agenda, Gallery, Members, Gathering, and Voting are contextual modules and should not overcrowd the bottom navigation.

## 9. Home Dashboard

Home should answer:
1. Kapan arisan berikutnya?
2. Di rumah siapa?
3. Berapa status iuran saya?
4. Siapa pemenang terakhir?
5. Berapa kas gathering?

Recommended hierarchy:

```text
Greeting
Next Arisan
Iuran Saya
Kas Gathering
Pemenang Terakhir
Role-specific Quick Actions
```

The gathering fund must be visually separate from money distributed to the arisan winner.

## 10. Iuran, Donasi, dan Kas Gathering

These are three different concepts and must never be visually conflated.

### Iuran
Show contribution amount, paid count, progress, and member status.

### Donasi
Separate optional module. Show total and donors independently.

### Kas Gathering
Show current balance, allocation rule, recent ledger, and event spending.

Example:

```text
KAS GATHERING
Rp4.250.000

10% dari iuran dialokasikan
ke kas gathering

[ Lihat Riwayat Kas ]
```

## 11. Gathering Fund & Voting

The gathering module is now a first-class product experience.

### Fund
Show:
- Current balance
- Allocation percentage
- Recent transactions
- Event allocations

Ledger should use simple language:

```text
+ Rp50.000  Alokasi iuran
- Rp1.500.000  Gathering Keluarga 2026
```

### Voting
Flow:

```text
Voting → Decided → Completed
```

Voting screen:

```text
GATHERING KELUARGA 2026

Pilih tujuan:
○ Wisata ke Bandung
○ Makan bersama
○ Villa Puncak

1 orang = 1 suara

[ VOTE ]
```

After submit:

```text
✓ Suara kamu sudah tercatat
Pilihan tidak dapat diubah.
```

Show voting progress:

```text
12 / 17 anggota sudah memilih
██████████████░░░ 71%
```

The UI must explain that voting closes automatically when all active members have voted.

Recommended default: **private voting**, showing totals without exposing individual choices, unless the family explicitly chooses open voting.

## 12. Digital Kocokan

The kocokan is the signature experience.

### Preparation
Show:
- Eligible member count
- Repeat-winner rule
- Participant list
- Admin-only start action

Always show the active rule before the draw.

### Animation
Use a full-screen experience with large names/avatars, countdown, motion, suspense, and synchronized result.

### Winner
```text
🎉

SELAMAT!

[ LARGE AVATAR ]

BUDI RASIJAN

Pemenang Periode #9

Rp8.500.000

Tuan Rumah Berikutnya
```

Gold can be emphasized here.

## 13. Arisan History

Use a timeline, not a dense table.

```text
RIWAYAT ARISAN

● #9
  15 Oktober
  🏆 Budi Rasijan
  🏠 Host: Budi

● #8
  15 Agustus
  🏆 Ahmad Rasijan
  🏠 Host: Ahmad
```

Optional statistics:
- Total periods
- Members who have won
- Members who have hosted
- Members who have never hosted

## 14. Event Agenda

Use a vertical stepper:

```text
✓ Kumpul
✓ Yasin & Sholawat
✓ Donasi (optional)
● Makan
○ Kocokan
○ Serah Terima Uang
○ Foto Bersama
○ Penutupan
```

Donation must be configurable/omittable because it is optional.

Admin changes should appear in realtime for members.

## 15. Gallery

Gallery is part of the long-term family archive.

Use a 3-column grid grouped by period. All members can upload photos under the current product rules.

## 16. Members

Member overview:
- Avatar
- Name
- Role
- Active/inactive
- Optional winning/hosting information

Member detail:
- Photo
- Name
- Contact
- Address
- Role
- Active status
- Arisan history

Do not expose unnecessary personal data on overview screens.

## 17. Authentication & Invite

Authentication is passwordless Email Magic Link/OTP.

Recommended flow:

```text
BANI RASIJAN
Arisan Keluarga

Email
[________________]

[ Kirim Kode / Magic Link ]

Belum bergabung?
Gunakan kode undangan.
```

Invite:

```text
Masukkan Kode Undangan
[ ABC123 ]
[ Bergabung ]
```

Do not expose technical invite expiry/hash details.

## 18. Notifications

MVP:
- H-7
- H-1

Example:

```text
Arisan BANI RASIJAN
Arisan berikutnya tinggal 7 hari.
Tanggal: 15 Oktober
Tuan rumah: Ahmad
```

Gathering voting notifications should clearly indicate that voting is open.

## 19. Weak Network UX

Prioritize caching:
- Current period
- Host
- Date
- Address
- Payment summary
- Agenda state

When offline:

```text
Offline
Data terakhir diperbarui: 10:42
```

Never show a mutation as successful until server confirmation.

## 20. UI States

Every data-driven screen needs:
- Loading
- Empty
- Error
- Success

Never expose raw Supabase/PostgreSQL errors.

## 21. Accessibility

- 44–48px minimum touch target
- 15–16px body text
- Strong contrast
- Text labels for important actions
- Semantic icons
- Support text scaling
- Never rely on color alone

## 22. Dark Mode

Not required for MVP. Use semantic tokens now so dark mode can be added later.

## 23. Flutter Theme

Use:

```text
lib/core/theme/
```

Recommended:
```text
AppColors
AppTypography
AppSpacing
AppRadii
AppElevation
AppMotion
```

Do not hard-code colors inside feature screens.

## 24. Final UX Direction

> **Keluarga berkumpul, arisan tercatat, keputusan transparan, kenangan tersimpan.**

BANI RASIJAN should feel personal first and administrative second.
