import 'package:flutter/foundation.dart';
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
  debugPrint('[donationListProvider] periodId: $periodId');
  if (periodId.isEmpty) {
    debugPrint('[donationListProvider] periodId is empty, returning []');
    return [];
  }
  final donations = await repository.getDonationsForPeriod(periodId);
  debugPrint('[donationListProvider] donations fetched: ${donations.length}');
  return donations;
});
