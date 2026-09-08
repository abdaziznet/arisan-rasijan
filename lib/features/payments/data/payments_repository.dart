import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  PaymentsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Mengambil nilai tetap alokasi kas gathering dari app_settings (rupiah).
  Future<double> _getGatheringFundAmount() async {
    try {
      debugPrint('[PaymentsRepo] Fetching gathering_fund_amount...');
      // Coba key baru dulu
      final data = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'gathering_fund_amount')
          .maybeSingle();

      if (data != null && data['value'] != null) {
        final amount = double.tryParse(data['value'] as String) ?? 0;
        debugPrint('[PaymentsRepo] gathering_fund_amount from DB = Rp$amount');
        return amount;
      }

      debugPrint('[PaymentsRepo] gathering_fund_amount NOT FOUND in app_settings, returning 0');
      debugPrint('[PaymentsRepo] ⚠️ Admin harus simpan nilai kas gathering di Pengaturan Admin');
      return 0;
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR fetching gathering_fund_amount: $e');
      return 0;
    }
  }

  /// Menyimpan pembayaran baru ke database beserta alokasi ke fund_ledger.
  Future<void> addPayment(Payment payment) async {
    try {
      final session = _client.auth.currentSession;
      final recordedBy = session?.user.id;
      debugPrint('[PaymentsRepo] recordedBy: $recordedBy');

      // Ambil nilai tetap alokasi kas gathering
      final gatheringFundAmount = await _getGatheringFundAmount();
      final allocatedToFund = gatheringFundAmount;
      final netAmount = payment.amount - allocatedToFund;
      debugPrint('[PaymentsRepo] contributionAmount: ${payment.amount}');
      debugPrint('[PaymentsRepo] allocated_to_fund: $allocatedToFund');
      debugPrint('[PaymentsRepo] netAmount (stored): $netAmount');

      // Insert pembayaran dengan alokasi
      final paymentData = payment.toMap();
      paymentData.remove('id'); // Biarkan Supabase generate UUID
      paymentData['amount'] = netAmount; // Simpan nilai bersih
      paymentData['allocated_to_fund'] = allocatedToFund;
      paymentData['status'] = 'paid';
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
        debugPrint('[PaymentsRepo] No fund allocation (amount is 0)');
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
      debugPrint('[PaymentsRepo] getCurrentMemberPayments userId=$userId');
      if (userId == null || userId.isEmpty) return [];

      // Cari periode aktif (status upcoming atau ongoing)
      final periodData = await _client
          .from('arisan_periods')
          .select('id, event_date')
          .inFilter('status', ['upcoming', 'ongoing'])
          .order('event_date', ascending: true)
          .limit(1)
          .maybeSingle();
      debugPrint('[PaymentsRepo] getCurrentMemberPayments periodData=$periodData');
      if (periodData == null) return [];
      final periodId = periodData['id'] as String;
      final eventDate = DateTime.parse(periodData['event_date'] as String);

      // Cek apakah tanggal hari ini sudah sesuai tanggal acara
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      debugPrint('[PaymentsRepo] getCurrentMemberPayments today=$today eventDay=$eventDay');
      if (today.isBefore(eventDay)) return [];

      // Cek apakah ada pembayaran LUNAS untuk user ini di periode aktif
      final data = await _client
          .from('payments')
          .select()
          .eq('member_id', userId)
          .eq('period_id', periodId)
          .eq('status', 'paid')
          .limit(1);

      debugPrint('[PaymentsRepo] getCurrentMemberPayments found=${data.length}');
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

  /// Mengambil semua anggota aktif beserta status pembayaran untuk periode tertentu.
  Future<List<MemberPaymentStatus>> getMembersWithPaymentStatus(String periodId) async {
    try {
      // Ambil semua anggota aktif
      final membersData = await _client
          .from('profiles')
          .select('id, full_name, photo_url')
          .eq('is_active', true)
          .order('full_name');

      // Ambil semua pembayaran untuk periode ini
      final paymentsData = await _client
          .from('payments')
          .select('member_id, status, amount, payment_method, paid_at')
          .eq('period_id', periodId);

      // Build map pembayaran by member_id
      final paymentsMap = <String, Map<String, dynamic>>{};
      for (final p in paymentsData) {
        paymentsMap[p['member_id'] as String] = p;
      }

      // Gabungkan
      return membersData.map((m) {
        final memberId = m['id'] as String;
        final payment = paymentsMap[memberId];
        return MemberPaymentStatus(
          memberId: memberId,
          fullName: m['full_name'] as String? ?? '',
          photoUrl: m['photo_url'] as String?,
          isPaid: payment != null && payment['status'] == 'paid',
          amount: payment?['amount'] as double?,
          paymentMethod: payment?['payment_method'] as String?,
          paidAt: payment?['paid_at'] != null
              ? DateTime.parse(payment!['paid_at'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR getMembersWithPaymentStatus: $e');
      return [];
    }
  }

  /// Toggle status pembayaran anggota (paid/unpaid) untuk periode tertentu.
  Future<void> togglePaymentStatus({
    required String memberId,
    required String periodId,
    required bool markAsPaid,
  }) async {
    try {
      final session = _client.auth.currentSession;
      final recordedBy = session?.user.id;

      if (markAsPaid) {
        // Ambil contribution_amount dari periode
        final periodData = await _client
            .from('arisan_periods')
            .select('contribution_amount')
            .eq('id', periodId)
            .maybeSingle();
        final contributionAmount =
            (periodData?['contribution_amount'] as num?)?.toDouble() ?? 0;

        // Ambil nilai tetap alokasi kas gathering
        final gatheringFundAmount = await _getGatheringFundAmount();
        final allocatedToFund = gatheringFundAmount;
        final netAmount = contributionAmount - allocatedToFund;
        debugPrint('[PaymentsRepo] togglePaymentStatus contributionAmount=$contributionAmount allocatedToFund=$allocatedToFund netAmount=$netAmount');

        // Cek apakah record sudah ada
        final existing = await _client
            .from('payments')
            .select('id')
            .eq('period_id', periodId)
            .eq('member_id', memberId)
            .maybeSingle();

        final baseData = <String, dynamic>{
          'period_id': periodId,
          'member_id': memberId,
          'amount': netAmount,
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          if (recordedBy != null && recordedBy.isNotEmpty)
            'recorded_by': recordedBy,
        };

        String recordId;
        if (existing != null) {
          await _client
              .from('payments')
              .update(baseData)
              .eq('id', existing['id'] as String);
          recordId = existing['id'] as String;
          debugPrint('[PaymentsRepo] Payment UPDATED as PAID for member=$memberId');
        } else {
          final inserted = await _client
              .from('payments')
              .insert(baseData)
              .select('id')
              .single();
          recordId = inserted['id'] as String;
          debugPrint('[PaymentsRepo] Payment INSERTED as PAID for member=$memberId');
        }

        // Step 2: Update allocated_to_fund terpisah (workaround jika trigger mereset)
        await _client
            .from('payments')
            .update({'allocated_to_fund': allocatedToFund})
            .eq('id', recordId);
        debugPrint('[PaymentsRepo] allocated_to_fund set to $allocatedToFund for record=$recordId');
      } else {
        // Update status jadi unpaid + reset allocated_to_fund
        await _client
            .from('payments')
            .update({
              'status': 'unpaid',
              'paid_at': null,
              'allocated_to_fund': 0,
            })
            .eq('member_id', memberId)
            .eq('period_id', periodId);
        debugPrint('[PaymentsRepo] Payment marked as UNPAID for member=$memberId');
      }
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR togglePaymentStatus: $e');
      throw Exception('Gagal mengubah status pembayaran: $e');
    }
  }

  /// Total kas gathering dari seluruh periode (SUM allocated_to_fund).
  Future<double> getTotalGatheringFund() async {
    try {
      final data = await _client
          .from('payments')
          .select('member_id, status, allocated_to_fund');

      debugPrint('[PaymentsRepo] getTotalGatheringFund: ${data.length} total rows');
      double total = 0;
      for (final row in data) {
        final status = row['status'];
        final atf = (row['allocated_to_fund'] as num?)?.toDouble() ?? 0;
        final memberId = row['member_id'];
        debugPrint('[PaymentsRepo]   row: member=$memberId status=$status allocated_to_fund=$atf');
        if (status == 'paid') {
          total += atf;
        }
      }
      debugPrint('[PaymentsRepo] Total gathering fund: Rp$total');
      return total;
    } catch (e) {
      debugPrint('[PaymentsRepo] ERROR getTotalGatheringFund: $e');
      return 0;
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
