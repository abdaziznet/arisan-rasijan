import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_prayer_repository.dart';
import '../domain/daily_prayer.dart';

final dailyPrayerRepositoryProvider = Provider<DailyPrayerRepository>(
  (ref) => AssetDailyPrayerRepository(),
);

final dailyPrayersProvider = FutureProvider<List<DailyPrayer>>(
  (ref) => ref.watch(dailyPrayerRepositoryProvider).loadAll(),
);
