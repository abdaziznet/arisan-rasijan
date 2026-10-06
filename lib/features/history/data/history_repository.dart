import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../domain/period_history_model.dart';

class HistoryRepository {
  HistoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Riwayat = periode berstatus completed saja, terbaru dulu.
  Future<List<PeriodHistoryModel>> getHistory() async {
    debugPrint('[HistoryRepository.getHistory] start');
    try {
      // PostgREST tidak mendukung sintaks SQL `as` untuk alias kolom.
      // Pilih `event_date` sekali; startDate & endDate keduanya dari kolom ini.
      final response = await _client.from('arisan_periods').select('''
          id,
          period_number,
          event_date,
          total_collected,
          host:host_id(id,full_name),
          winner:winner_id(id,full_name)
        ''').eq('status', 'completed').order('period_number', ascending: false);

      final list = response as List<dynamic>;
      debugPrint(
        '[HistoryRepository.getHistory] '
        'filter=status:completed order=period_number:desc '
        'rows=${list.length}',
      );
      return list.map((json) {
        final periodId = json['id'] as String;
        final periodNumber = json['period_number'] as int;
        final eventDate = DateTime.parse(json['event_date'] as String);
        final totalCollected =
            (json['total_collected'] as num?)?.toDouble() ?? 0.0;
        final hostJson = json['host'] as Map<String, dynamic>?;
        final winnerJson = json['winner'] as Map<String, dynamic>?;
        final hostId = hostJson?['id'] as String? ?? '';
        final hostName = hostJson?['full_name'] as String? ?? '';
        final winnerId = winnerJson?['id'] as String? ?? '';
        final winnerName = winnerJson?['full_name'] as String? ?? '';
        return PeriodHistoryModel(
          periodId: periodId,
          periodNumber: periodNumber,
          hostId: hostId,
          hostName: hostName,
          winnerId: winnerId,
          winnerName: winnerName,
          startDate: eventDate,
          endDate: eventDate,
          totalCollected: totalCollected,
        );
      }).toList();
    } catch (e) {
      debugPrint('[HistoryRepository.getHistory] ERROR: $e');
      rethrow;
    }
  }

  /// Stream riwayat: dengarkan perubahan baris completed saja,
  /// lalu ambil ulang via getHistory agar nama host/winner tetap terjoin.
  Stream<List<PeriodHistoryModel>> watchHistory() {
    return _client
        .from('arisan_periods')
        .stream(primaryKey: ['id'])
        .eq('status', 'completed')
        .order('period_number', ascending: false)
        .asyncMap((_) => getHistory());
  }
}
