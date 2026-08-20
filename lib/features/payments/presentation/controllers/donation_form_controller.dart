import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/payment_model.dart';
import '../providers/payments_providers.dart';
import 'payment_list_controller.dart';

enum DonationFormState { initial, loading, success, error }

class DonationFormController extends StateNotifier<DonationFormState> {
  DonationFormController(this.ref) : super(DonationFormState.initial);

  final Ref ref;

  Future<bool> submitDonation({
    String? memberId, // Bisa null untuk donatur anonim
    required double amount,
    String? notes,
  }) async {
    state = DonationFormState.loading;
    try {
      final periodId = ref.read(activePeriodIdProvider);

      final newDonation = Donation(
        id: '', // Supabase akan generate UUID
        periodId: periodId,
        memberId: memberId,
        amount: amount,
        notes: notes,
        donatedAt: DateTime.now(),
      );

      await ref.read(paymentsRepositoryProvider).addDonation(newDonation);
      state = DonationFormState.success;
      ref.invalidate(donationListProvider);
      return true;
    } catch (e) {
      state = DonationFormState.error;
      return false;
    }
  }
}
