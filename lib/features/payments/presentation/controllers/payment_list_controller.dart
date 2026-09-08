import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../periods/presentation/providers/periods_providers.dart';
import '../../domain/payment_model.dart';
import '../providers/payments_providers.dart';

final activePeriodIdProvider = Provider<String>((ref) {
  final period = ref.watch(activePeriodProvider).valueOrNull?.id ?? '';
  return period;
});

final paymentListProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  final periodId = ref.watch(activePeriodIdProvider);
  if (periodId.isEmpty) return [];
  return repository.getPaymentsForPeriod(periodId);
});

final donationListProvider = FutureProvider<List<Donation>>((ref) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  final periodId = ref.watch(activePeriodIdProvider);
  if (periodId.isEmpty) return [];
  return repository.getDonationsForPeriod(periodId);
});
