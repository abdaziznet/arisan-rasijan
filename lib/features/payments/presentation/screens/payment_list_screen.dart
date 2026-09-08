import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/domain/member_model.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/payment_list_controller.dart';
import '../providers/payments_providers.dart';
import '../../domain/payment_model.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../widgets/payment_form_dialog.dart';
import '../widgets/payment_list_item.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ?? false;
    final activePeriod = ref.watch(activePeriodProvider).valueOrNull;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isEventDay = activePeriod != null &&
        activePeriod.eventDate.year == today.year &&
        activePeriod.eventDate.month == today.month &&
        activePeriod.eventDate.day == today.day;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Iuran & Donasi'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
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
        floatingActionButton: isAdmin && isEventDay
            ? FloatingActionButton.extended(
                onPressed: () => PaymentFormDialog.show(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                elevation: 4,
              )
            : null,
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
  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentListProvider);
    final membersAsync = ref.watch(membersControllerProvider);
    final activePeriod = ref.watch(activePeriodProvider).valueOrNull;

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isBeforeEvent = activePeriod != null &&
              activePeriod.eventDate.isAfter(today);

          return AppEmptyState(
            icon: Icons.monetization_on_outlined,
            title: isBeforeEvent
                ? 'Periode Arisan Belum Dimulai'
                : 'Belum Ada Pembayaran',
            message: isBeforeEvent
                ? 'Pencatatan iuran akan tersedia pada tanggal acara periode ini.'
                : 'Data iuran untuk periode ini masih kosong.',
          );
        }

        // Build member map for name lookup
        final members = membersAsync.valueOrNull;
        final membersMap = members != null
            ? {for (final m in members) m.id: m}
            : <String, MemberModel>{};

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(paymentListProvider);
            ref.invalidate(donationListProvider);
            ref.invalidate(currentMemberHasPaidProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              80,
            ),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final member = membersMap[payment.memberId];
              final memberName = member?.fullName ?? 'Anggota';
              final memberInitials = member != null
                  ? member.fullName.isNotEmpty
                      ? member.fullName.substring(
                          0,
                          member.fullName.length.clamp(0, 2),
                        ).toUpperCase()
                      : null
                  : null;

              return PaymentListItem(
                memberName: memberName,
                amount: payment.amount,
                paymentMethod: payment.paymentMethod,
                paidAt: payment.paidAt,
                isPaid: true,
                memberInitials: memberInitials,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        );
      },
      loading: () => const AppLoading(),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.refresh(paymentListProvider),
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
          return AppEmptyState(
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
