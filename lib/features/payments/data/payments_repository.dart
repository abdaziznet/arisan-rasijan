import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  PaymentsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Mengambil persentase alokasi kas gathering dari app_settings.
  Future<double> _getGatheringFundPercentage() async {
    try {
      debugPrint('[PaymentsRepo] Fetching gathering_fund_percentage...');
      final data = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'gathering_fund_percentage')
          .maybeSingle();

      debugPrint('[PaymentsRepo] app_settings response: $data');
      if (data == null || data['value'] == null) {
        debugPrint('[PaymentsRepo] gathering_fund_percentage not found, defaulting to 0');
        return 0;
      }
      final percentage = double.tryParse(data['value'] as String) ?? 0;
      debugPrint('[PaymentsRepo] gathering_fund_percentage = $percentage%');
      return percentage;
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR fetching gathering_fund_percentage: $e');
      return 0;
    }
  }

  /// Menyimpan pembayaran baru ke database beserta alokasi ke fund_ledger.
  Future<void> addPayment(Payment payment) async {
    try {
      final session = _client.auth.currentSession;
      final recordedBy = session?.user.id;
      debugPrint('[PaymentsRepo] recordedBy: $recordedBy');

      // Hitung alokasi ke kas gathering
      final percentage = await _getGatheringFundPercentage();
      final allocatedToFund = payment.amount * (percentage / 100);
      debugPrint('[PaymentsRepo] amount: ${payment.amount}');
      debugPrint('[PaymentsRepo] allocated_to_fund: $allocatedToFund');

      // Insert pembayaran dengan alokasi
      final paymentData = payment.toMap();
      paymentData.remove('id'); // Biarkan Supabase generate UUID
      paymentData['allocated_to_fund'] = allocatedToFund;
      if (recordedBy != null && recordedBy.isNotEmpty) {
        paymentData['recorded_by'] = recordedBy;
      }
      debugPrint('[PaymentsRepo] Inserting payment: $paymentData');

      await _client.from('payments').insert(paymentData);
      debugPrint('[PaymentsRepo] Payment inserted to payments table');

      // Insert ke fund_ledger jika ada alokasi
      if (allocatedToFund > 0) {
        final ledgerData = <String, dynamic>{
          'type': 'contribution_allocation',
          'amount': allocatedToFund,
          'period_id': payment.periodId,
          'description': 'Alokasi kas gathering dari iuran anggota',
        };
        if (recordedBy != null && recordedBy.isNotEmpty) {
          ledgerData['created_by'] = recordedBy;
        }
        debugPrint('[PaymentsRepo] Inserting fund_ledger: $ledgerData');
        await _client.from('fund_ledger').insert(ledgerData);
        debugPrint('[PaymentsRepo] Fund ledger entry inserted');
      } else {
        debugPrint('[PaymentsRepo] No fund allocation (percentage is 0)');
      }
    } catch (e, st) {
      debugPrint('[PaymentsRepo] ERROR: $e');
      debugPrint('[PaymentsRepo] Stack: $st');
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

  /// Mengambil pembayaran milik user login untuk periode aktif.
  Future<List<Payment>> getCurrentMemberPayments() async {
    try {
      final session = _client.auth.currentSession;
      final userId = session?.user.id;
      if (userId == null || userId.isEmpty) return [];

      // profiles.id = auth user id, langsung pakai userId sebagai member_id
      // Cari periode aktif
      final periodData = await _client
          .from('arisan_periods')
          .select('id')
          .eq('status', 'active')
          .maybeSingle();
      if (periodData == null) return [];
      final periodId = periodData['id'] as String;

      // Cek apakah ada pembayaran untuk user ini di periode aktif
      final data = await _client
          .from('payments')
          .select('id')
          .eq('member_id', userId)
          .eq('period_id', periodId)
          .limit(1);

      debugPrint('[PaymentsRepo] getCurrentMemberPayments userId=$userId periodId=$periodId count=${data.length}');
      return data.map((item) => Payment.fromMap(item)).toList();
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR getCurrentMemberPayments: $e');
      return [];
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
