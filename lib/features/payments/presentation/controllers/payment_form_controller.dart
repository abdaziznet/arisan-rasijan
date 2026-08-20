import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/payment_model.dart';
import '../providers/payments_providers.dart';
import 'payment_list_controller.dart';

enum PaymentFormState { initial, loading, success, error }

class PaymentFormController extends StateNotifier<PaymentFormState> {
  PaymentFormController(this.ref) : super(PaymentFormState.initial);

  final Ref ref;

  Future<bool> submitPayment({
    required String memberId,
    required double amount,
    required PaymentMethod method,
  }) async {
    state = PaymentFormState.loading;
    try {
      final periodId = ref.read(activePeriodIdProvider);
      final recordedBy = ref.read(authRepositoryProvider).currentUser!.id;

      final newPayment = Payment(
        id: '', // Supabase akan generate UUID
        periodId: periodId,
        memberId: memberId,
        amount: amount,
        paymentMethod: method,
        paidAt: DateTime.now(),
        recordedBy: recordedBy,
      );

      await ref.read(paymentsRepositoryProvider).addPayment(newPayment);
      state = PaymentFormState.success;
      // Invalidate list provider agar data di-refresh
      ref.invalidate(paymentListProvider);
      return true;
    } catch (e) {
      state = PaymentFormState.error;
      return false;
    }
  }
}
