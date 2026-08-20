import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/event_checklist_model.dart';
import '../providers/event_checklist_providers.dart';

class EventChecklistController extends AsyncNotifier<List<EventChecklistModel>> {
  @override
  Future<List<EventChecklistModel>> build() async {
    // This will be overridden by the stream provider for real-time updates
    return [];
  }

  Future<void> loadChecklistForPeriod(String periodId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(eventChecklistRepositoryProvider);
      return repo.getChecklistForPeriod(periodId);
    });
  }

  Future<void> createDefaultChecklistForPeriod(String periodId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(eventChecklistRepositoryProvider);
      return repo.createDefaultChecklistForPeriod(periodId);
    });
  }

  Future<void> toggleChecklistItem(EventChecklistModel item) async {
    final updatedItem = item.copyWith(
      isCompleted: !item.isCompleted,
      completedAt: !item.isCompleted ? DateTime.now() : null,
    );

    state = await AsyncValue.guard(() async {
      final repo = ref.read(eventChecklistRepositoryProvider);
      await repo.updateChecklistItem(updatedItem);

      // Return updated list from current state
      final currentList = state.valueOrNull ?? [];
      return currentList.map((e) => e.id == item.id ? updatedItem : e).toList();
    });
  }
}