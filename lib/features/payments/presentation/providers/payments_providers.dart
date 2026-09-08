import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payments_repository.dart';
import '../../domain/payment_model.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../controllers/payment_form_controller.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});

final paymentFormProvider =
    StateNotifierProvider<PaymentFormController, PaymentFormState>((ref) {
  return PaymentFormController(ref);
});

/// Check if current member has paid for the active period.
final currentMemberHasPaidProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(paymentsRepositoryProvider);
  final payments = await repo.getCurrentMemberPayments();
  return payments.isNotEmpty;
});

/// Daftar semua anggota aktif beserta status pembayaran untuk periode aktif.
final memberPaymentStatusListProvider =
    FutureProvider<List<MemberPaymentStatus>>((ref) async {
  final repo = ref.watch(paymentsRepositoryProvider);
  final period = ref.watch(activePeriodProvider).valueOrNull;
  if (period == null) return [];
  return repo.getMembersWithPaymentStatus(period.id);
});
