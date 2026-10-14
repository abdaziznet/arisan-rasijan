import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/event_checklist_model.dart';
import '../providers/event_checklist_providers.dart';

class EventChecklistController
    extends FamilyAsyncNotifier<List<EventChecklistModel>, String> {
  @override
  Future<List<EventChecklistModel>> build(String arg) async {
    final repo = ref.watch(eventChecklistRepositoryProvider);
    return repo.getChecklistForPeriod(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(eventChecklistRepositoryProvider);
      return repo.getChecklistForPeriod(arg);
    });
  }

  Future<void> createDefaultChecklist({BuildContext? context}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(eventChecklistRepositoryProvider);
      return repo.createDefaultChecklistForPeriod(arg);
    });
    state = result;

    if (result.hasError && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat agenda: ${result.error}')),
      );
    }
  }

  Future<void> addAgendaItem(String stepName, {BuildContext? context}) async {
    final currentList = state.valueOrNull ?? [];
    final nextOrder = currentList.isEmpty
        ? 1
        : currentList.map((e) => e.stepOrder).reduce((a, b) => a > b ? a : b) + 1;

    try {
      final repo = ref.read(eventChecklistRepositoryProvider);
      final newItem = await repo.addAgendaItem(
        periodId: arg,
        stepName: stepName.trim(),
        stepOrder: nextOrder,
      );
      state = AsyncValue.data([...currentList, newItem]);
    } catch (e, st) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan agenda: $e')),
        );
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeAgendaItem(String itemId, {BuildContext? context}) async {
    final currentList = state.valueOrNull ?? [];
    final updatedList = currentList.where((e) => e.id != itemId).toList();

    // Reassign continuous step_order
    final reorderedList = List.generate(updatedList.length, (i) {
      return updatedList[i].copyWith(stepOrder: i + 1);
    });

    // Optimistic UI update
    state = AsyncValue.data(reorderedList);

    try {
      final repo = ref.read(eventChecklistRepositoryProvider);
      await repo.deleteAgendaItem(itemId);
      await repo.updateItemsOrder(reorderedList);
    } catch (e, st) {
      // Revert if failed
      state = AsyncValue.data(currentList);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus agenda: $e')),
        );
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderAgendaItems(
    int oldIndex,
    int newIndex, {
    BuildContext? context,
  }) async {
    final currentList = List<EventChecklistModel>.from(state.valueOrNull ?? []);
    debugPrint(
      '[EventChecklist] Reorder started: oldIndex=$oldIndex, '
      'newIndex=$newIndex, itemCount=${currentList.length}',
    );
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= currentList.length ||
        newIndex < 0 ||
        newIndex >= currentList.length) {
      debugPrint('[EventChecklist] Reorder ignored: invalid or unchanged indices.');
      return;
    }

    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);

    // Reassign stepOrder (1-based index)
    final reorderedList = List.generate(currentList.length, (i) {
      return currentList[i].copyWith(stepOrder: i + 1);
    });
    debugPrint(
      '[EventChecklist] Optimistic order: '
      '${reorderedList.map((item) => '${item.id}:${item.stepOrder}').toList()}',
    );

    // Optimistic UI update
    state = AsyncValue.data(reorderedList);

    try {
      final repo = ref.read(eventChecklistRepositoryProvider);
      await repo.updateItemsOrder(reorderedList);
      debugPrint('[EventChecklist] Reorder save completed.');
    } catch (e, st) {
      debugPrint('[EventChecklist] Reorder save failed: $e');
      debugPrintStack(stackTrace: st);
      // Rollback on failure
      ref.invalidateSelf();
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah urutan agenda: $e')),
        );
      }
      state = AsyncValue.error(e, st);
    }
  }

  // Backward compatibility methods
  Future<void> loadChecklistForPeriod(String periodId) async {
    await refresh();
  }

  Future<void> createDefaultChecklistForPeriod(
    String periodId, {
    BuildContext? context,
  }) async {
    await createDefaultChecklist(context: context);
  }

  Future<void> toggleChecklistItem(EventChecklistModel item) async {
    final updatedItem = item.copyWith(
      isCompleted: !item.isCompleted,
      completedAt: !item.isCompleted ? DateTime.now() : null,
    );

    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentList.map((e) => e.id == item.id ? updatedItem : e).toList(),
    );

    final repo = ref.read(eventChecklistRepositoryProvider);
    await repo.updateChecklistItem(updatedItem);
  }
}
