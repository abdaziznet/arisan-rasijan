import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/periods_repository_provider.dart';
import '../../domain/period_model.dart';

class PeriodsController extends AsyncNotifier<List<PeriodModel>> {
  @override
  Future<List<PeriodModel>> build() async {
    final repo = ref.watch(periodsRepositoryProvider);
    return repo.getPeriods();
  }

  Future<void> refreshPeriods() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(periodsRepositoryProvider);
      return repo.getPeriods();
    });
  }

  Future<void> createPeriod(PeriodModel period) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(periodsRepositoryProvider);
      await repo.createPeriod(period);
      return repo.getPeriods();
    });
  }

  Future<void> updatePeriod(PeriodModel period) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(periodsRepositoryProvider);
      await repo.updatePeriod(period);
      return repo.getPeriods();
    });
  }
}
