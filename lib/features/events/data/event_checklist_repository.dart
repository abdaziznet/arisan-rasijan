import 'package:flutter/foundation.dart';
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
    final items = list
        .map((json) => EventChecklistModel.fromJson(json))
        .toList();
    debugPrint(
      '[EventChecklist] Loaded from database: '
      '${items.length} items, '
      'id:stepOrder=${items.map((item) => '${item.id}:${item.stepOrder}').toList()}',
    );
    return items;
  }

  Future<EventChecklistModel> addAgendaItem({
    required String periodId,
    required String stepName,
    required int stepOrder,
  }) async {
    final response = await _client
        .from('event_checklist')
        .insert({
          'period_id': periodId,
          'step_name': stepName,
          'step_order': stepOrder,
          'is_completed': false,
        })
        .select()
        .single();

    return EventChecklistModel.fromJson(response);
  }

  Future<void> deleteAgendaItem(String id) async {
    await _client.from('event_checklist').delete().eq('id', id);
  }

  Future<void> updateItemsOrder(List<EventChecklistModel> items) async {
    // The controller has already assigned each model its new stepOrder, so
    // comparing item.stepOrder with the target index here would skip every
    // update. Persist the supplied order for every item instead.
    final futures = <Future<void>>[
      for (final item in items)
        _updateItemOrder(item.id, item.stepOrder),
    ];
    debugPrint(
      '[EventChecklist] Saving order: itemCount=${items.length}, '
      'rowsToUpdate=${futures.length}',
    );
    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
        debugPrint('[EventChecklist] All order updates returned successfully.');
      } catch (error, stackTrace) {
        debugPrint('[EventChecklist] Order update request failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    } else {
      debugPrint('[EventChecklist] Order already matches database values.');
    }
  }

  Future<void> _updateItemOrder(String itemId, int newOrder) async {
    final response = await _client
        .from('event_checklist')
        .update({'step_order': newOrder})
        .eq('id', itemId)
        .select('id, step_order');

    final updatedRows = response as List<dynamic>;
    debugPrint(
      '[EventChecklist] Database update response: '
      'itemId=$itemId, rows=${updatedRows.length}, '
      'requestedStepOrder=$newOrder',
    );
    if (updatedRows.length != 1) {
      throw StateError(
        'Urutan agenda tidak tersimpan. Baris agenda tidak ditemukan atau '
        'tidak memiliki izin untuk diperbarui.',
      );
    }

    final persistedOrder =
        ((updatedRows.single as Map<String, dynamic>)['step_order'] as num?)
            ?.toInt();
    debugPrint(
      '[EventChecklist] Persisted stepOrder=$persistedOrder',
    );
    if (persistedOrder != newOrder) {
      throw StateError('Urutan agenda gagal diverifikasi setelah disimpan.');
    }
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
    final payload = steps.map((s) {
      final json = s.toJson();
      json.remove('id'); // Let database generate UUID
      return json;
    }).toList();

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
