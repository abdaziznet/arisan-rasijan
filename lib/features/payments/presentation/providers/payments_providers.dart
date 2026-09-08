import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payments_repository.dart';
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
