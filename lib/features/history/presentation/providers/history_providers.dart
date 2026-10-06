import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/history_repository.dart';
import '../../domain/period_history_model.dart';

/// Provider for HistoryRepository instance.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

/// FutureProvider that fetches the entire history list once.
final historyListProvider = FutureProvider<List<PeriodHistoryModel>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return await repo.getHistory();
});

/// StreamProvider that listens for realtime updates to period history.
final historyStreamProvider = StreamProvider<List<PeriodHistoryModel>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.watchHistory();
});

/// Controller for history to allow manual refresh.
final historyControllerProvider = Provider<HistoryController>((ref) {
  return HistoryController(ref);
});

class HistoryController {
  final Ref _ref;
  HistoryController(this._ref);

  void refreshHistory() {
    final _ = _ref.refresh(historyListProvider);
  }
}