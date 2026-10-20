import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tahlilan_repository.dart';
import '../domain/tahlil_reading.dart';

final tahlilanRepositoryProvider = Provider<TahlilanRepository>(
  (ref) => AssetTahlilanRepository(),
);

final tahlilanReadingsProvider = FutureProvider<List<TahlilReading>>(
  (ref) => ref.watch(tahlilanRepositoryProvider).loadAll(),
);
