import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/payment_model.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../../../gathering/presentation/providers/gathering_providers.dart';
import '../providers/payments_providers.dart';
import 'payment_list_controller.dart';

enum PaymentFormState { initial, loading, success, error }

class PaymentFormController extends StateNotifier<PaymentFormState> {
  PaymentFormController(this.ref) : super(PaymentFormState.initial);

  final Ref ref;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void resetState() {
    _errorMessage = null;
    state = PaymentFormState.initial;
  }

  Future<bool> submitPayment({
    required String memberId,
    required double amount,
    required PaymentMethod method,
  }) async {
    debugPrint('[PaymentForm] === submitPayment START ===');
    debugPrint('[PaymentForm] memberId: $memberId');
    debugPrint('[PaymentForm] amount: $amount');
    debugPrint('[PaymentForm] method: ${method.name}');

    state = PaymentFormState.loading;
    _errorMessage = null;
    try {
      final period = ref.read(activePeriodProvider).valueOrNull;
      if (period == null) {
        debugPrint('[PaymentForm] ERROR: Active period is null');
        _errorMessage = 'Tidak ada periode arisan aktif';
        state = PaymentFormState.error;
        return false;
      }
      final periodId = period.id;
      debugPrint('[PaymentForm] periodId: $periodId');

      final payment = Payment(
        id: '',
        periodId: periodId,
        memberId: memberId,
        amount: amount,
        paymentMethod: method,
        paidAt: DateTime.now(),
        recordedBy: '',
        allocatedToFund: 0,
      );
      debugPrint('[PaymentForm] Payment object created, calling repository...');

      await ref.read(paymentsRepositoryProvider).addPayment(payment);

      debugPrint('[PaymentForm] Payment saved successfully');
      state = PaymentFormState.success;
      ref.invalidate(paymentListProvider);
      ref.invalidate(fundLedgerProvider);
      ref.invalidate(currentMemberHasPaidProvider);
      debugPrint('[PaymentForm] === submitPayment END (success) ===');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[PaymentForm] ERROR: $e');
      debugPrint('[PaymentForm] Stack trace: $stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = PaymentFormState.error;
      return false;
    }
  }
}
