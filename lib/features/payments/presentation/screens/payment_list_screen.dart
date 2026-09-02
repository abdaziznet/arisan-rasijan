import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../controllers/payment_list_controller.dart';
import '../widgets/payment_form_dialog.dart';
import '../widgets/payment_list_item.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(currentMemberProfileProvider).valueOrNull?.isAdmin ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Iuran & Donasi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'IURAN'),
              Tab(text: 'DONASI'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PaymentsTab(),
            _DonationsTab(), // Akan dibuat
          ],
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  // TODO: Tentukan dialog mana yang dibuka berdasarkan tab aktif
                  PaymentFormDialog.show(context);
                },
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentListProvider);
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const AppEmptyState(
            title: 'Belum Ada Pembayaran',
            message: 'Data iuran untuk periode ini masih kosong.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return PaymentListItem(
              title: 'Member ID: ${payment.memberId}',
              amount: payment.amount,
              isPaid: true,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    return donationsAsync.when(
      data: (donations) {
        if (donations.isEmpty) {
          return const AppEmptyState(
            title: 'Belum Ada Donasi',
            message: 'Data donasi untuk periode ini masih kosong.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            return PaymentListItem(
              title: 'Donatur ID: ${donation.memberId ?? 'Anonim'}',
              amount: donation.amount,
              isPaid: true, // Donasi selalu dianggap 'lunas'
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
