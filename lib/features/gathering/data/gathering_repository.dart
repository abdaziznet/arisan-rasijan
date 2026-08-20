import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../domain/gathering_event_model.dart';
import '../domain/gathering_poll_option_model.dart';
import '../domain/gathering_vote_model.dart';
import '../domain/fund_ledger_model.dart';

class GatheringRepository {
  GatheringRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<GatheringEventModel>> getEvents() async {
    final response = await _client
        .from('gathering_events')
        .select('*')
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((json) => GatheringEventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<GatheringEventModel?> getEvent(String eventId) async {
    final response = await _client
        .from('gathering_events')
        .select('*')
        .eq('id', eventId)
        .maybeSingle();

    if (response == null) return null;
    return GatheringEventModel.fromJson(response);
  }

  Future<GatheringEventModel> createEvent(GatheringEventModel event) async {
    final payload = event.toJson();
    payload.remove('id');

    final response = await _client
        .from('gathering_events')
        .insert(payload)
        .select('*')
        .single();

    return GatheringEventModel.fromJson(response);
  }

  Future<GatheringEventModel> updateEvent(GatheringEventModel event) async {
    final payload = event.toJson();
    // Keep id for update, but don't send it in payload if not needed
    // Supabase update by id in where clause
    final response = await _client
        .from('gathering_events')
        .update(payload)
        .eq('id', event.id)
        .select('*')
        .single();

    return GatheringEventModel.fromJson(response);
  }

  Future<List<GatheringPollOptionModel>> getPollOptions(String eventId) async {
    final response = await _client
        .from('gathering_poll_options')
        .select('*')
        .eq('gathering_event_id', eventId);

    final list = response as List<dynamic>;
    return list
        .map((json) => GatheringPollOptionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<FundLedgerModel>> getFundLedger() async {
    final response = await _client
        .from('fund_ledger')
        .select('*')
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((json) => FundLedgerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPollOption(GatheringPollOptionModel option) async {
    final payload = option.toJson();
    payload.remove('id');
    await _client.from('gathering_poll_options').insert(payload);
  }

  Future<void> submitVote(GatheringVoteModel vote) async {
    await _client.from('gathering_votes').insert(vote.toJson());
  }

  Future<bool> hasMemberVoted({
    required String eventId,
    required String memberId,
  }) async {
    final response = await _client
        .from('gathering_votes')
        .select('id')
        .eq('gathering_event_id', eventId)
        .eq('member_id', memberId)
        .maybeSingle();

    return response != null;
  }

  Future<int> getVoteCount(String optionId) async {
    final response = await _client
        .from('gathering_votes')
        .select('id')
        .eq('option_id', optionId);

    final list = response as List<dynamic>;
    return list.length;
  }

  Future<Map<String, String>> getAppSettings() async {
    final response = await _client.from('app_settings').select('key,value');

    final list = response as List<dynamic>;
    return {
      for (final row in list)
        (row as Map<String, dynamic>)['key'] as String:
            (row)['value'] as String? ?? '',
    };
  }

  Future<void> updateAppSetting({
    required String key,
    required String value,
    required String updatedBy,
  }) async {
    await _client.from('app_settings').upsert({
      'key': key,
      'value': value,
      'updated_by': updatedBy,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, num>> getGatheringTally(String eventId) async {
    final response = await _client.rpc(
      'get_gathering_vote_tally',
      params: {'p_gathering_event_id': eventId},
    );

    final list = response as List<dynamic>;
    return {
      for (final row in list)
        ((row as Map<String, dynamic>)['option_id'] as String):
            (row['vote_count'] as num),
    };
  }

  Future<void> updateEventDetails({
    required String eventId,
    required DateTime eventDate,
    required double fundUsed,
  }) async {
    await _client.from('gathering_events').update({
      'event_date': eventDate.toIso8601String().split('T').first,
      'fund_used': fundUsed,
      'status': 'completed',
      'closed_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);

    // Also record the gathering expense in the fund ledger
    await _client.from('fund_ledger').insert({
      'type': 'gathering_expense',
      'amount': -fundUsed, // Negative for expense
      'gathering_event_id': eventId,
      'description': 'Penggunaan dana untuk acara gathering',
      'created_by': eventId, // TODO: Get actual user ID from context
    });
  }
}