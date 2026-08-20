import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_checklist_repository_provider.dart';
import '../../domain/event_checklist_model.dart';
import '../controllers/event_checklist_controller.dart';

final eventChecklistControllerProvider =
    AsyncNotifierProvider<EventChecklistController, List<EventChecklistModel>>(
  () => EventChecklistController(),
);

final eventChecklistStreamProvider =
    StreamProvider.family<List<EventChecklistModel>, String>((ref, periodId) {
  final repo = ref.watch(eventChecklistRepositoryProvider);
  return repo.watchChecklistForPeriod(periodId);
});