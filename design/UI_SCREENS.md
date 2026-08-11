# BANI RASIJAN — UI Screen Specification

**Tagline:** Arisan Keluarga  
**Version:** 2.0

## 1. Primary Navigation

```text
Beranda | Iuran | Arisan | Profil
```

Contextual modules:
- Agenda
- Gallery
- Members
- Gathering
- Voting

## 2. Authentication

### Login
- Email
- Send OTP / magic link
- Invite onboarding entry

### Verification
- OTP / magic link result
- Resend
- Change email

### Profile Completion
- Full name
- Photo
- Phone
- Address where appropriate

## 3. Home

Member:
```text
Greeting
Next Arisan
My Payment
Gathering Fund
Latest Winner
Recent Gallery
```

Admin additionally gets:
```text
Catat Pembayaran
Agenda
Mulai Kocokan
Kelola Gathering
```

## 4. Iuran

Summary:
- Period
- Contribution amount
- Paid / active members
- Progress

Member list:
- Avatar
- Name
- Status
- Amount
- Method where relevant

Admin can update payment.

## 5. Donation

Separate from mandatory contribution:
- Total donation
- Number of donors
- Notes

## 6. Gathering Fund

Overview:
- Balance
- Allocation rule
- Recent ledger

Admin:
- Configure allocation percentage
- Record event usage

Member:
- View balance
- View ledger

## 7. Gathering Event

Admin creates:
- Event title
- Destination options
- Optional notes

Status:
```text
Voting → Decided → Completed
```

## 8. Gathering Voting

Before vote:
```text
Pilih satu tujuan

○ Bandung
○ Puncak
○ Makan bersama

[ Pilih ]
```

After vote:
```text
✓ Pilihan kamu sudah tersimpan
Pilihan tidak dapat diubah.
```

Progress:
```text
12 / 17 sudah vote
```

Result:
- Winning option
- Vote totals
- Completed state

## 9. Gathering Completion

Admin sets:
- Event date
- Fund used

Member view:
```text
GATHERING KELUARGA 2026

🏆 Wisata ke Bandung

20 Desember 2026
Dana digunakan: Rp1.500.000
```

## 10. Arisan Period Detail

Show:
- Period
- Date
- Host
- Host address
- Contribution
- Payment progress
- Agenda
- Winner
- Gallery

## 11. Kocokan

Preparation:
- Eligible count
- Repeat-winner rule
- Participant list
- Admin CTA

Animation:
- Full-screen
- Countdown
- Participant animation
- Synchronized result

Winner:
- Large avatar
- Name
- Amount
- Next host

## 12. Agenda

Vertical stepper. Donation step is optional.

Admin controls completion; members observe realtime progress.

## 13. History

Timeline grouped by year:
- Date
- Winner
- Host
- Amount
- Photo

## 14. Gallery

3-column grid grouped by period. All members may upload photos according to current product rules.

## 15. Members

Searchable list and member detail.

## 16. Profile

- Personal information
- Account
- Role
- Notification settings
- Sign out

## 17. Confirmation

Require confirmation for:
- Delete member
- Delete photo
- Start draw
- Manual correction
- Record gathering expense
- Other destructive actions

## 18. Realtime

Realtime UX is required for:
- Kocokan result
- Agenda
- Gathering fund
- Voting progress/result

Avoid full-screen refreshes.

## 19. Weak Network

Show cached data timestamp and explicit pending/offline states.

## 20. MVP Implementation Order

1. Authentication
2. Home
3. Iuran
4. Arisan Detail
5. Agenda
6. Kocokan
7. Winner
8. History
9. Gallery
10. Gathering Fund
11. Gathering Event
12. Voting
13. Members
14. Profile
