import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/event_checklist_model.dart';
import '../domain/event_checklist_steps.dart';

class EventChecklistRepository {
  EventChecklistRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<EventChecklistModel>> getChecklistForPeriod(String periodId) async {
    final response = await _client
        .from('event_checklist')
        .select()
        .eq('period_id', periodId)
        .order('step_order', ascending: true);

    final list = response as List<dynamic>;
    return list
        .map((json) => EventChecklistModel.fromJson(json))
        .toList();
  }

  Future<EventChecklistModel> updateChecklistItem(EventChecklistModel item) async {
    final payload = item.toJson();
    payload.remove('id');

    final response = await _client
        .from('event_checklist')
        .update(payload)
        .eq('id', item.id)
        .select()
        .single();

    return EventChecklistModel.fromJson(response);
  }

  Future<List<EventChecklistModel>> createDefaultChecklistForPeriod(String periodId) async {
    final steps = EventChecklistSteps.createDefaultForPeriod(periodId);
    final payload = steps.map((s) => s.toJson()).toList();

    final response = await _client
        .from('event_checklist')
        .insert(payload)
        .select();

    final list = response as List<dynamic>;
    return list
        .map((json) => EventChecklistModel.fromJson(json))
        .toList();
  }

  Stream<List<EventChecklistModel>> watchChecklistForPeriod(String periodId) {
    return _client
        .from('event_checklist')
        .stream(primaryKey: ['id'])
        .eq('period_id', periodId)
        .order('step_order', ascending: true)
        .map((data) => data
            .map((json) => EventChecklistModel.fromJson(json))
            .toList());
  }
}