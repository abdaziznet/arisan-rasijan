import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draw_model.dart';
import '../providers/draw_providers.dart';

class DrawController extends AsyncNotifier<DrawModel?> {
  @override
  FutureOr<DrawModel?> build() => null;

  Future<void> runDraw(String periodId) async {
    // Guard: validasi semua kondisi
    final allPaid = await ref.read(allMembersPaidProvider.future);
    if (!allPaid) {
      state = AsyncError('Belum semua anggota membayar iuran.', StackTrace.current);
      return;
    }
    final isDrawDay = ref.read(isDrawDayProvider);
    if (!isDrawDay) {
      state = AsyncError('Kocokan hanya bisa dijalankan pada hari-H acara.', StackTrace.current);
      return;
    }
    final isDone = await ref.read(isDrawAlreadyDoneProvider.future);
    if (isDone) {
      state = AsyncError('Kocokan untuk periode ini sudah selesai.', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(drawRepositoryProvider);
      return repo.runDraw(periodId);
    });
  }
}
