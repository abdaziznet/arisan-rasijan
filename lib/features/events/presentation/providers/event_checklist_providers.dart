import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_checklist_repository.dart';
import '../../domain/event_checklist_model.dart';
import '../controllers/event_checklist_controller.dart';

final eventChecklistRepositoryProvider = Provider<EventChecklistRepository>((ref) {
  return EventChecklistRepository();
});

final eventChecklistControllerProvider =
    AsyncNotifierProvider<EventChecklistController, List<EventChecklistModel>>(() {
  return EventChecklistController();
});

final eventChecklistStreamProvider = StreamProvider.autoDispose.family<
    List<EventChecklistModel>, String>((ref, periodId) {
  final repo = ref.watch(eventChecklistRepositoryProvider);
  return repo.watchChecklistForPeriod(periodId);
});