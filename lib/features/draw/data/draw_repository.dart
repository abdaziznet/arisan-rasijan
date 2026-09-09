import 'dart:async';

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
        .from('profiles')
        .select('*')
        .eq('is_active', true);

    // Get past winners
    final pastWinnersResp = await _client
        .from('arisan_periods')
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
          conducted_at,
          arisan_periods!inner(period_number),
          winner:profiles!winner_id(full_name)
        ''')
        .order('conducted_at', ascending: false);

    return (response as List).map((json) {
      final period = json['arisan_periods'] as Map<String, dynamic>;
      final winner = json['winner'] as Map<String, dynamic>;
      return DrawHistoryModel(
        id: json['id'] as String,
        periodId: json['period_id'] as String,
        periodNumber: period['period_number'] as int,
        winnerId: json['winner_id'] as String,
        winnerName: winner['full_name'] as String,
        createdAt: DateTime.parse(json['conducted_at'] as String),
      );
    }).toList();
  }

  /// Subscribes to realtime draw updates
  Stream<List<DrawHistoryModel>> watchDrawHistory() {
    // Realtime stream doesn't support joins natively, so we just
    // emit when a change happens and let the provider re-fetch
    // getDrawHistory(), OR we can use the provider to re-fetch.
    // For now, this stream is just an event emitter that triggers a refetch
    // But since the current provider expects List<DrawHistoryModel>, we'll map it
    // Wait, the current draw_providers.dart expects `watchDrawHistory()` to return a stream of data
    // We should change `drawHistoryStreamProvider` to poll or use this stream as a trigger.
    // Let's implement it with a query to getDrawHistory() whenever a realtime event comes.

    // Create a stream controller that fetches history when it receives an event
    late final StreamController<List<DrawHistoryModel>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<DrawHistoryModel>>(
      onListen: () async {
        // Initial fetch
        try {
          final history = await getDrawHistory();
          controller.add(history);
        } catch (e) {
          controller.addError(e);
        }

        // Subscribe to changes
        channel = _client
            .channel('public:draws')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'draws',
              callback: (payload) async {
                try {
                  final history = await getDrawHistory();
                  if (!controller.isClosed) {
                    controller.add(history);
                  }
                } catch (e) {
                  if (!controller.isClosed) {
                    controller.addError(e);
                  }
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }
}
