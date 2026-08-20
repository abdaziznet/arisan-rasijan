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
