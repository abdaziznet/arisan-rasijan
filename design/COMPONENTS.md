# BANI RASIJAN — Component Specification

**Tagline:** Arisan Keluarga  
**Version:** 2.0

## 1. Core

```text
AppButton
AppTextField
AppCard
AppAvatar
AppBadge
AppDialog
AppBottomSheet
AppSnackbar
AppEmptyState
AppErrorState
AppLoading
AppProgressBar
AppSectionHeader
```

## 2. Navigation

```text
AppBottomNavigation
AppTopBar
AppBackButton
```

## 3. Arisan

```text
PeriodCard
PeriodSummary
HostCard
WinnerCard
DrawParticipant
DrawCountdown
DrawAnimation
WinnerReveal
ArisanTimeline
```

## 4. Financial

```text
PaymentStatus
PaymentProgress
PaymentMemberTile
ContributionSummary
DonationSummary
FundBalanceCard
FundLedgerItem
```

Payment, donation, and gathering fund must remain visually distinct.

## 5. Gathering

```text
GatheringFundCard
GatheringEventCard
VotingOptionCard
VotingProgress
VotingResult
VoteSubmittedState
FundTransactionItem
```

VotingOptionCard states:
- Default
- Selected
- Submitted
- Winner
- Disabled

## 6. Event

```text
ChecklistItem
ChecklistStepper
EventStatus
EventPhotoGrid
PhotoViewer
```

## 7. Members

```text
MemberListTile
MemberAvatar
MemberRoleBadge
MemberStatusBadge
MemberHistorySummary
```

## 8. Feedback

```text
LoadingSkeleton
EmptyState
ErrorState
SuccessSnackbar
OfflineBanner
PendingActionBanner
ConfirmationDialog
```

## 9. Theme

Expose:
```text
AppColors
AppTypography
AppSpacing
AppRadii
AppElevation
AppMotion
```

## 10. Accessibility

Components must:
- Support semantic labels
- Respect text scaling
- Provide sufficient touch targets
- Never depend only on color
- Expose meaningful accessibility values

## 11. Realtime

Realtime changes should be represented with inline updates, progress changes, animations, or result reveals rather than disruptive full-screen refreshes.

## 12. Flutter Location

Shared:
```text
lib/core/widgets/
```

Theme:
```text
lib/core/theme/
```

Feature-specific widgets stay under their feature:
```text
lib/features/gathering/presentation/widgets/
```

## 13. Naming

Good:
```text
AppCard
AppButton
PaymentStatus
PeriodCard
WinnerCard
VotingOptionCard
```

Avoid screen-specific names such as `HomeGreenCard`.

## 14. Tokens

Features should use semantic tokens such as:
```text
AppColors.primary
AppColors.accent
AppColors.textPrimary
AppColors.success
```
instead of hard-coded color values.
