import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'periods_repository.dart';

final periodsRepositoryProvider = Provider<PeriodsRepository>((ref) {
  return PeriodsRepository();
});
