import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/payment_model.dart';
import '../providers/payments_providers.dart';
import 'payment_list_controller.dart';

enum DonationFormState { initial, loading, success, error }

class DonationFormController extends StateNotifier<DonationFormState> {
  DonationFormController(this.ref) : super(DonationFormState.initial);

  final Ref ref;

  Future<Donation?> submitDonation({
    required String memberId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    debugPrint('[DonationFormController] submitDonation called');
    state = DonationFormState.loading;
    try {
      final periodId = ref.read(activePeriodIdProvider);
      debugPrint('[DonationFormController] periodId: $periodId');
      if (periodId.isEmpty) {
        throw Exception('Belum ada periode arisan aktif.');
      }

      final newDonation = Donation(
        id: '', // Supabase akan generate UUID
        periodId: periodId,
        memberId: memberId,
        amount: amount,
        notes: notes,
        donatedAt: DateTime.now(),
        paymentMethod: paymentMethod,
        status: 'pending_payment',
      );

      debugPrint(
          '[DonationFormController] Attempting to add donation to repository');
      final created = await ref
          .read(paymentsRepositoryProvider)
          .createDonation(newDonation);
      debugPrint(
          '[DonationFormController] Donation added successfully to repository');

      state = DonationFormState.success;
      ref.invalidate(donationListProvider);
      debugPrint(
          '[DonationFormController] Donation marked as success, ref invalidated');
      return created;
    } catch (e, stackTrace) {
      debugPrint('[DonationFormController] EXCEPTION in submitDonation: $e');
      debugPrint('[DonationFormController] Stack trace: $stackTrace');
      state = DonationFormState.error;
      return null;
    }
  }
}
