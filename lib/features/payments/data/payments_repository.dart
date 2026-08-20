import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  PaymentsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Menyimpan pembayaran baru ke database.
  Future<void> addPayment(Payment payment) async {
    try {
      await _client.from('payments').insert(payment.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan pembayaran: $e');
    }
  }

  /// Mengambil semua donasi untuk periode tertentu.
  Future<List<Donation>> getDonationsForPeriod(String periodId) async {
    try {
      final data = await _client
          .from('donations')
          .select()
          .eq('period_id', periodId)
          .order('donated_at', ascending: false);

      return data.map((item) => Donation.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data donasi: $e');
    }
  }

  /// Mengambil semua pembayaran untuk periode tertentu.
  Future<List<Payment>> getPaymentsForPeriod(String periodId) async {
    try {
      final data = await _client
          .from('payments')
          .select()
          .eq('period_id', periodId)
          .order('paid_at', ascending: false);

      return data.map((item) => Payment.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pembayaran: $e');
    }
  }

  /// Menyimpan donasi baru ke database.
  Future<void> addDonation(Donation donation) async {
    try {
      await _client.from('donations').insert(donation.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan donasi: $e');
    }
  }
}
