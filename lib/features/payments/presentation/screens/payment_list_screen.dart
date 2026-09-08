import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/payment_list_controller.dart';
import '../providers/payments_providers.dart';
import '../../domain/payment_model.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../widgets/payment_list_item.dart';
import '../../../gathering/presentation/providers/gathering_providers.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Iuran & Donasi'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'IURAN'),
              Tab(text: 'DONASI'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PaymentsTab(),
            _DonationsTab(),
          ],
        ),
        floatingActionButton: null,
      ),
    );
  }
}

class _PaymentsTab extends ConsumerStatefulWidget {
  const _PaymentsTab();

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  String _searchQuery = '';

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberPaymentStatusListProvider);
    final activePeriod = ref.watch(activePeriodProvider).valueOrNull;
    final isAdmin =
        ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ?? false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isBeforeEvent = activePeriod != null &&
        activePeriod.eventDate.isAfter(today);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return AppEmptyState(
            icon: Icons.monetization_on_outlined,
            title: isBeforeEvent
                ? 'Periode Arisan Belum Dimulai'
                : 'Belum Ada Anggota',
            message: isBeforeEvent
                ? 'Pencatatan iuran akan tersedia pada tanggal acara periode ini.'
                : 'Data anggota untuk periode ini masih kosong.',
          );
        }

        // Filter by search
        final filtered = _searchQuery.isEmpty
            ? members
            : members
                .where((m) =>
                    m.fullName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

        final paidCount = members.where((m) => m.isPaid).length;
        final totalCount = members.length;
        final unpaidCount = totalCount - paidCount;

        return Column(
          children: [
            // Summary Card
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: unpaidCount == 0
                      ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (unpaidCount == 0
                            ? AppColors.success
                            : AppColors.primary)
                        .withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unpaidCount == 0
                          ? Icons.check_circle_rounded
                          : Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$paidCount dari $totalCount anggota sudah bayar',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (unpaidCount > 0)
                          Text(
                            '$unpaidCount anggota belum membayar',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          )
                        else
                          Text(
                            'Semua iuran periode ini sudah lunas',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: totalCount > 0 ? paidCount / totalCount : 0,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        Text(
                          '${((paidCount / totalCount) * 100).toInt()}%',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari anggota...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ),

            // Reminder button (admin only)
            if (isAdmin && unpaidCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyReminderMessage(
                      members.where((m) => !m.isPaid).toList(),
                      activePeriod,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin Pesan Pengingat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            // Member list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(memberPaymentStatusListProvider);
                  ref.invalidate(currentMemberHasPaidProvider);
                  ref.invalidate(paymentListProvider);
                  ref.invalidate(totalGatheringFundProvider);
                },
                child: filtered.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 48),
                          AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Anggota Tidak Ditemukan',
                            message: 'Tidak ada anggota yang cocok dengan pencarian.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          80,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final member = filtered[index];
                          return _MemberPaymentTile(
                            member: member,
                            isAdmin: isAdmin,
                            initials: _getInitials(member.fullName),
                            onTap: isAdmin
                                ? () => _toggleStatus(member)
                                : null,
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.refresh(memberPaymentStatusListProvider),
      ),
    );
  }

  void _toggleStatus(MemberPaymentStatus member) async {
    final newStatus = !member.isPaid;
    try {
      await ref.read(paymentsRepositoryProvider).togglePaymentStatus(
            memberId: member.memberId,
            periodId: ref.read(activePeriodProvider).valueOrNull!.id,
            markAsPaid: newStatus,
          );
      ref.invalidate(memberPaymentStatusListProvider);
      ref.invalidate(currentMemberHasPaidProvider);
      ref.invalidate(paymentListProvider);
      ref.invalidate(totalGatheringFundProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  void _copyReminderMessage(
      List<MemberPaymentStatus> unpaidMembers, dynamic period) {
    final periodInfo = period != null
        ? 'Periode #${period.periodNumber}'
        : 'periode arisan';
    final amount = period?.contributionAmount != null
        ? 'Rp${period!.contributionAmount!.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'
        : '';

    final names =
        unpaidMembers.map((m) => '• ${m.fullName}').join('\n');

    final message = '''
Assalamu'alaikum Wr. Wb.

Mohon maaf mengingatkan untuk pembayaran iuran $periodInfo.
Nominal: $amount

Yang belum membayar:
$names

Mohon untuk segera melakukan pembayaran. Terima kasih 🙏
'''.trim();

    Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan pengingat berhasil disalin ke clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _MemberPaymentTile extends StatelessWidget {
  const _MemberPaymentTile({
    required this.member,
    required this.isAdmin,
    required this.initials,
    this.onTap,
  });

  final MemberPaymentStatus member;
  final bool isAdmin;
  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: member.isPaid
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: member.isPaid
                    ? LinearGradient(
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.textSecondary,
                          AppColors.textSecondary.withValues(alpha: 0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: member.isPaid
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22)
                    : Text(
                        initials,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name + Amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (member.amount != null)
                    Text(
                      currencyFormatter.format(member.amount),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: member.isPaid
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: member.isPaid
                      ? AppColors.success.withValues(alpha: 0.25)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    member.isPaid
                        ? Icons.check_circle_outline
                        : Icons.schedule_rounded,
                    size: 14,
                    color: member.isPaid
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    member.isPaid ? 'Lunas' : 'Belum',
                    style: AppTypography.caption.copyWith(
                      color: member.isPaid
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron for admin
            if (isAdmin) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DonationsTab extends ConsumerWidget {
  const _DonationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(donationListProvider);
    final membersAsync = ref.watch(membersControllerProvider);

    return donationsAsync.when(
      data: (donations) {
        if (donations.isEmpty) {
          return const AppEmptyState(
            icon: Icons.monetization_on_outlined,
            title: 'Belum Ada Donasi',
            message: 'Data donasi untuk periode ini masih kosong.',
          );
        }

        final membersMap = membersAsync.whenOrNull(
          data: (members) => {for (final m in members) m.id: m},
        ) ?? {};

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            80,
          ),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            final member = donation.memberId != null
                ? membersMap[donation.memberId]
                : null;
            final memberName = member?.fullName ?? 'Anonim';

            return PaymentListItem(
              memberName: memberName,
              amount: donation.amount,
              paymentMethod: PaymentMethod.cash,
              paidAt: donation.donatedAt,
              isPaid: true,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        );
      },
      loading: () => const AppLoading(),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.refresh(donationListProvider),
      ),
    );
  }
}
