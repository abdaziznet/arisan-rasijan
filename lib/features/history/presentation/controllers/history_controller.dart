import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/history_repository.dart';
import '../../domain/period_history_model.dart';

class HistoryController extends StateNotifier<AsyncValue<List<PeriodHistoryModel>>> {
  HistoryController(this._historyRepository) : super(const AsyncValue.loading()) {
    _load();
  }

  final HistoryRepository _historyRepository;

  Future<void> _load() async {
    try {
      final result = await _historyRepository.getHistory();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshHistory() async {
    state = const AsyncValue.loading();
    try {
      final result = await _historyRepository.getHistory();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, AsyncValue<List<PeriodHistoryModel>>>(
  (ref) => HistoryController(HistoryRepository()),
);
