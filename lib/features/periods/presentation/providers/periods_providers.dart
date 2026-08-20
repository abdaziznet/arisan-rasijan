import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/periods_repository_provider.dart';
import '../../domain/period_model.dart';
import '../controllers/periods_controller.dart';

final periodsControllerProvider =
    AsyncNotifierProvider<PeriodsController, List<PeriodModel>>(() {
  return PeriodsController();
});

final activePeriodProvider = FutureProvider<PeriodModel?>((ref) async {
  final repo = ref.watch(periodsRepositoryProvider);
  return repo.getActivePeriod();
});
