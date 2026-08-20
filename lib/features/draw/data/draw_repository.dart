import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/members/domain/member_model.dart';
import '../domain/draw_model.dart';

class DrawRepository {
  DrawRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  /// Fetches candidates for the draw: active members excluding past winners
  /// until all active members have won (then cycle resets).
  Future<List<MemberModel>> getCandidates(String periodId) async {
    // Get active members
    final activeMembersResp = await _client
        .from('members')
        .select('*')
        .eq('is_active', true);

    // Get past winners
    final pastWinnersResp = await _client
        .from('periods')
        .select('winner_id')
        .not('winner_id', 'is', null);

    final activeMembers = (activeMembersResp as List)
        .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final pastWinnerIds = (pastWinnersResp as List)
        .map((p) => p['winner_id'] as String)
        .toSet();

    // If all active members have won, reset the cycle
    if (pastWinnerIds.length >= activeMembers.length) {
      return activeMembers;
    }

    // Otherwise exclude past winners
    return activeMembers.where((m) => !pastWinnerIds.contains(m.id)).toList();
  }

  /// Runs the draw via Edge Function
  Future<DrawModel> runDraw(String periodId) async {
    final response = await _client.functions.invoke(
      'run-draw',
      body: {'periodId': periodId},
    );

    // FunctionResponse doesn't have error getter in newer versions
    // Check if data contains error or use try-catch
    if (response.data == null) {
      throw Exception('Failed to run draw: no response data');
    }

    // Check if response has error field
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) {
      throw Exception(data['error']['message'] as String? ?? 'Unknown error');
    }

    return DrawModel.fromJson(data);
  }

  /// Fetches draw history with winner details
  Future<List<DrawHistoryModel>> getDrawHistory() async {
    final response = await _client
        .from('draws')
        .select('''
          id,
          period_id,
          winner_id,
          created_at,
          periods!inner(period_number),
          winner:members!winner_id(full_name)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final period = json['periods'] as Map<String, dynamic>;
      final winner = json['winner'] as Map<String, dynamic>;
      return DrawHistoryModel(
        id: json['id'] as String,
        periodId: json['period_id'] as String,
        periodNumber: period['period_number'] as int,
        winnerId: json['winner_id'] as String,
        winnerName: winner['full_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    }).toList();
  }

  /// Subscribes to realtime draw updates
  Stream<List<DrawHistoryModel>> watchDrawHistory() {
    return _client
        .from('draws')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) {
              final period = json['periods'] as Map<String, dynamic>;
              final winner = json['winner'] as Map<String, dynamic>;
              return DrawHistoryModel(
                id: json['id'] as String,
                periodId: json['period_id'] as String,
                periodNumber: period['period_number'] as int,
                winnerId: json['winner_id'] as String,
                winnerName: winner['full_name'] as String,
                createdAt: DateTime.parse(json['created_at'] as String),
              );
            }).toList());
  }
}
