import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../domain/period_history_model.dart';

class HistoryRepository {
  HistoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<PeriodHistoryModel>> getHistory() async {
    final response = await _client
        .from('arisan_periods')
        .select('''
          id,
          period_number,
          event_date as start_date,
          event_date as end_date,
          total_collected,
          host:host_id (id, full_name),
          winner:winner_id (id, full_name)
        ''')
        .order('period_number', ascending: true);

    final list = response as List<dynamic>;
    return list.map((json) {
      final periodId = json['id'] as String;
      final periodNumber = json['period_number'] as int;
      final startDate = DateTime.parse(json['start_date'] as String);
      final endDate = DateTime.parse(json['end_date'] as String);
      final totalCollected = (json['total_collected'] as num?)?.toDouble() ?? 0.0;
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
        startDate: startDate,
        endDate: endDate,
        totalCollected: totalCollected,
      );
    }).toList();
  }

  Stream<List<PeriodHistoryModel>> watchHistory() {
    return _client
        .from('arisan_periods')
        .stream(primaryKey: ['id'])
        .order('period_number', ascending: true)
        .map((data) => (data as List<dynamic>).map((json) {
          final periodId = json['id'] as String;
          final periodNumber = json['period_number'] as int;
          final startDate = DateTime.parse(json['event_date'] as String);
          final endDate = DateTime.parse(json['event_date'] as String);
          final totalCollected = (json['total_collected'] as num?)?.toDouble() ?? 0.0;
          final hostJson = json['host_id'] != null ? json['host'] as Map<String, dynamic>? : null;
          final winnerJson = json['winner_id'] != null ? json['winner'] as Map<String, dynamic>? : null;
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
            startDate: startDate,
            endDate: endDate,
            totalCollected: totalCollected,
          );
        }).toList());
  }
}
